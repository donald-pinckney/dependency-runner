#!/usr/bin/env python3
# This script manages MinNPM experiments on Discovery, using Slurm.
#
import subprocess
import time
import argparse
import sys
import os
import glob
import json
import csv
import concurrent.futures
import cfut # Adrian Sampson's clusterfutures package.
from util import suppressed_iterator, write_json, read_json, chunked_or_distributed

def main():
    parser = argparse.ArgumentParser(
        description='Manage MinNPM experiments on Discovery.')
    parser.add_argument(
        'command', 
        choices=['run', 'gather'],
        help='Subcommand to run')
    args = parser.parse_args(sys.argv[1:2])
    if args.command == 'run':
        run(sys.argv[2:])
    elif args.command == 'gather':
        gather(sys.argv[2:])

def gather(argv):
    parser = argparse.ArgumentParser(
        description='Gather results after running an experiment')
    parser.add_argument(
        'directory',
        help='Directory to gather results from')
    args = parser.parse_args(argv)
    Gather(args.directory).gather()

class Gather(object):

    def __init__(self, directory):
        self.directory = os.path.normpath(directory)
        self.solvers = [
            'vanilla'
        ] + [
            os.sep.join(os.path.normpath(p).split(os.sep)[-3:]) 
            for p in glob.glob(f'{self.directory}/rosette/*/*/')
        ]
        print(f'Gathering results for the solvers: {self.solvers}')

    def projects_for_solver(self, solver: str):
        """
        The projects on which a particular solver ran.
        """
        p = os.path.join(self.directory, solver)
        return [f for f in os.listdir(p) if os.path.isdir(os.path.join(p, f))]

    def num_deps(self, project):
        """
        Calculates the number of dependencies. This function assumes that
        'npm install' was sucessful. It is critical that the check is performed
        correctly: if not, it will false report zero dependencies.
        """
        p = os.path.join(
            project,
            'package',
            'node_modules',
            '.package-lock.json')
        # NPM does not create the node_modules directory for packages with
        # zero dependencies. However, it also does not create node_modules for
        # packages that fail to install.
        if not os.path.isfile(p):
            return 0
        with open(p, 'r') as f:
            data = json.load(f)
            n = 0
            for _, v in data['packages'].items():
                if 'link' in v and v['link']:
                    continue
                n += 1
            return n

    def project_times(self, dir: str):
        """
        Times with both solves for the project.
        """
        durable_status_path = os.path.join(dir, 'package', 'experiment.json')
        transient_status_path = os.path.join(dir, 'package', 'error.json')
        if os.path.exists(durable_status_path):
            p_result = read_json(durable_status_path)
        elif os.path.exists(transient_status_path):
            p_result = read_json(transient_status_path)
        else:
            print(f'No status for {dir}')
            p_result = { 'status': 'unavailable' }


        status = p_result['reason'] if 'reason' in p_result else p_result['status']
        time = p_result['time'] if 'time' in p_result else None
        return (time, self.num_deps(dir), status)

    def gather(self):
        output_path = os.path.join(self.directory, 'results.csv') 
        with open(output_path, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['Project','Rosette','Consistency','Minimize','Time','NDeps', 'Status'])
            for mode_configuration in MODE_CONFIGURATIONS:
                mode_dir = mode_configuration_target(self.directory, mode_configuration)
                print(f'Processing a mode ...', mode_dir)
                with concurrent.futures.ThreadPoolExecutor(max_workers=100) as executor:
                    for (p, result) in executor.map(lambda p: (p, self.project_times(os.path.join(mode_dir, p))),  self.projects_for_solver(mode_dir)):
                        if result is None:
                            continue
                        (time, deps, status) = result
                        is_rosette = mode_configuration['rosette']
                        writer.writerow([
                            p,
                            is_rosette,
                            mode_configuration['consistency'] if is_rosette else '',
                            mode_configuration['minimize'] if is_rosette else '',
                            time,
                            deps,
                            status])

MODE_CONFIGURATIONS = [
    { 'rosette': False },
    { 'rosette': True, 'consistency': 'npm', 'minimize': 'min_oldness,min_num_deps' },
    { 'rosette': True, 'consistency': 'npm', 'minimize': 'min_num_deps,min_oldness' },
    { 'rosette': True, 'consistency': 'npm', 'minimize': 'min_duplicates,min_oldness' },
    { 'rosette': True, 'consistency': 'npm', 'minimize': 'min_oldness,min_duplicates' },
    { 'rosette': True, 'consistency': 'pip', 'minimize': 'min_oldness,min_num_deps' },
    { 'rosette': True, 'consistency': 'pip', 'minimize': 'min_num_deps,min_oldness' }
]

def run(argv):
    parser = argparse.ArgumentParser(
        description='Benchmark MinNPM on a directory of NPM projects')
    parser.add_argument('--tarball-dir', required=True,
        help='Directory with tarballs of Node packages')
    parser.add_argument('--target', required=True,
      help='Directory with NPM projects')
    parser.add_argument('--timeout', type=int, default=600,
        help='Timeout for npm')
    parser.add_argument('--cpus-per-task', type=int, default=24,
       help='Number of CPUs to request on each node')
    args = parser.parse_args(argv)

    tarball_dir = os.path.normpath(args.tarball_dir)
    target = os.path.normpath(args.target)
    Run(tarball_dir, target, MODE_CONFIGURATIONS, args.timeout, args.cpus_per_task).run()

def solve_command(mode_configuration):
    if mode_configuration['rosette']:
        return ['minnpm', 'install', '--prefer-offline', '--no-audit', '--rosette',
                '--ignore-scripts',
                '--consistency', mode_configuration['consistency'], 
                '--minimize', mode_configuration['minimize'] ]
    else:
        return 'minnpm install --prefer-offline --no-audit --omit dev --omit peer --omit optional --ignore-scripts'.split(' ')    

def mode_configuration_target(target_base, mode_configuration):
    if mode_configuration['rosette']:
        return os.path.join(target_base, 'rosette',
            mode_configuration['consistency'],
            mode_configuration['minimize'])
    else:
        return os.path.join(target_base, 'vanilla')


def package_target(target_base, mode_configuration, package_name):
    return os.path.join(mode_configuration_target(target_base, mode_configuration), package_name)

class Run(object):

    def __init__(self, tarball_dir, target, mode_configurations, timeout, cpus_per_task):
        self.target = target
        self.tarball_dir = tarball_dir
        self.timeout = timeout
        self.cpus_per_task = cpus_per_task
        self.mode_configurations = mode_configurations
        self.sbatch_lines = [
            "#SBATCH --time=00:15:00",
            "#SBATCH --partition=express",
            "#SBATCH --mem=8G",
            # This rules out the few nodes that are older than Haswell.
            # https://rc-docs.northeastern.edu/en/latest/hardware/hardware_overview.html#using-the-constraint-flag
            "$SBATCH --constraint=haswell|broadwell|skylake_avx512|zen2|zen|cascadelake",
            f'#SBATCH --cpus-per-task={cpus_per_task}',
            "module load discovery nodejs",
            "export PATH=$PATH:/home/a.guha/bin:/work/arjunguha-research-group/software/bin",
            "eval `spack load --sh z3`"
        ]

    def run_chunk(self, pkgs):
        print(f'Will handle {len(pkgs)}')
        # Tip: Cannot use ProcessPoolExecutor with the ClusterFutures executor. It seems like
        # ProcessPoolExector forks the process with the same command-line arguments, including
        # loading ClusterFutures's remote library, and that makes things go awry.
        errs = [ ]
        with concurrent.futures.ThreadPoolExecutor(max_workers=self.cpus_per_task) as executor:
            for err in suppressed_iterator(executor.map(self.run_minnpm, pkgs)):
                if err is not None:
                    errs.append(err)
        if len(errs) == 0:
            return None
        return '\n'.join(errs)
    
    def run(self):
        print(f'Listing package-configuration pairs ...')
        pkgs = self.list_pkg_paths()
        print(f'Will run on {len(pkgs)} configurations.')
        pkg_chunks = chunked_or_distributed(pkgs,
            max_groups=49, optimal_group_size=self.cpus_per_task)

        with cfut.SlurmExecutor(additional_setup_lines = self.sbatch_lines, keep_logs=True) as executor:
            for err in suppressed_iterator(executor.map(self.run_chunk, pkg_chunks)):
                if err is not None:
                    print(err)

    def list_pkg_paths(self):
        results = [ ]
        for package_tgz in os.listdir(self.tarball_dir):
            package_name = os.path.basename(package_tgz).replace('.tgz', '')
            for mode_configuration in self.mode_configurations:
                t = package_target(self.target, mode_configuration, package_name)
                result_file = os.path.join(t, "package", "experiment.json")
                if not os.path.isfile(result_file):
                    results.append((os.path.join(self.tarball_dir, package_tgz), t, mode_configuration))
        return results

    def get_npmstatus(self, path):
        with open(path, 'r') as out:
            lines = [ line.strip() for line in out.readlines() ]
        # The error code is usually on the first line. But, the MinNPM solver
        # prints stuff that appears before it.
        err_code = [ line for line in lines if line.startswith('npm ERR! code') ]
        if len(err_code) != 1:
            return None
        pieces = err_code[0].split(' ')
        if len(pieces) != 4:
            return None
        return pieces[3]

    def unpack_tarball_if_needed(self, tgz, target):
        if os.path.isdir(os.path.join(target, 'package')):
            return
        
        os.makedirs(target)
        if subprocess.call(['tar', '-C', target, '-xzf', tgz], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) != 0:
                return f'Error unpacking {tgz}'

    def run_minnpm(self, pkg_info):
        start_time = time.time()
        try:
            (tgz, pkg_target, mode_configuration) = pkg_info
            pkg_path = f'{pkg_target}/package'
            self.unpack_tarball_if_needed(tgz, pkg_target)
            output_path = f'{pkg_path}/experiment.out'
            with open(output_path, 'wt') as out:
                exit_code = subprocess.Popen(solve_command(mode_configuration),
                    cwd=pkg_path,
                    stdout=out,
                    stderr=out).wait(self.timeout)
            duration = time.time() - start_time
            output_status_path = f'{pkg_path}/experiment.json'
            error_status_path = f'{pkg_path}/error.json'
            if exit_code == 0:
                write_json(output_status_path,
                    { 'status': 'success', 'time': duration })
                return None
            status = self.get_npmstatus(output_path)
            if status in [ 'ERESOLVE', 'ETARGET', 'EUNSUPPORTEDPROTOCOL', 'EBADPLATFORM' ]:
                # TODO(arjun): This is for compatibility with older data. If
                # we do a totally fresh run, can refactor to stick reason into
                # status and remove the 'cannot_install' status.
                write_json(output_status_path, { 'status': 'cannot_install', 'reason': status })
                return None
            write_json(error_status_path, { 
                'status': 'unexpected', 
                'detail': output_path
             })
            return f'Failed: {pkg_path}'
        except subprocess.TimeoutExpired:
            write_json(error_status_path, { 'status': 'timeout' })
            return f'Timeout: {pkg_path}'
        except BaseException as e:
            write_json(error_status_path, {
                'status': 'unexpected',
                'detail': e.__str__()
            })                
            return f'Exception: {pkg_path} {e}'

if __name__ == '__main__':
    start = time.time()
    main()
    end = time.time()
    duration = int(end - start)
    print(f'Time taken: {duration} seconds')