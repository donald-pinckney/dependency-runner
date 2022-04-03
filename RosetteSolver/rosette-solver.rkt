#lang rosette

; (current-bitwidth 18) ; 32
; (output-smt "z3-debugging/")

(require "load-query.rkt")
(require "graph-sketching.rkt")
(require "solution.rkt")
(require "write-solution.rkt")
(require "graph-constraints.rkt")
(require "graph-optimization.rkt")
(require rosette/solver/smt/z3)
(current-solver
 ;; TODO : figure out path
 (z3 #:path "/home/elleven/code/pacsolve/RosetteSolver/z3/build/z3"
     #:options (hash
                ':model.user_functions "false"
                )))


(define INPUT-SOURCE
  (if (= 2 (vector-length (current-command-line-arguments)))
      (vector-ref (current-command-line-arguments) 0)
      (error "Incorrect number of command line arguments")))

(define QUERY (read-input-query INPUT-SOURCE))

;;; -------------------------------------------
;;; Actually doing the solve!
;;; -------------------------------------------


(define G (graph* QUERY))

(define (rosette-sol->solution sol)
  (if (sat? sol)
      (solution #t (evaluate G sol))
      (solution #f "Failed to solve constraints :(")))

; (pretty-display (optimize-graph QUERY G))

(define sol
  (optimize
   #:minimize (optimize-graph QUERY G)
   #:guarantee (check-graph QUERY G)))

(write-solution QUERY (rosette-sol->solution sol))

