#lang racket/base

;; This module provides abbreviations that are used to construct types
;; and data that show up in types. These are intended for internal use
;; within Typed Racket implementation code.

(require "../utils/utils.rkt"
         racket/list
         racket/match
         racket/function
         racket/undefined
         racket/function

         (prefix-in c: (contract-req))
         (rep rep-utils type-rep prop-rep object-rep values-rep)
         (types numeric-tower prefab)
         ;; Using this form so all-from-out works
         "base-abbrev.rkt" "match-expanders.rkt"

         ;; signature env req here is so it is statically required by
         ;; the code loaded during typechecking, otherwise we get
         ;; a `reference to a module that is not available` error
         ;; from references generated by init-envs
         (env signature-env)

         (for-syntax racket/base syntax/parse)

         ;; for base type contracts and predicates
         ;; use '#%place to avoid the other dependencies of `racket/place`
         (for-template
           racket/base
           racket/contract/base
           racket/undefined
           (only-in racket/pretty pretty-print-style-table?)
           (only-in racket/udp udp?)
           (only-in racket/tcp tcp-listener?)
           (only-in racket/flonum flvector?)
           (only-in racket/extflonum extflvector?)
           (only-in racket/fixnum fxvector?)
           (only-in racket/future fsemaphore?)
           (only-in '#%place place? place-channel?))
         (only-in racket/pretty pretty-print-style-table?)
         (only-in racket/udp udp?)
         (only-in racket/tcp tcp-listener?)
         (only-in racket/flonum flvector?)
         (only-in racket/extflonum extflvector?)
         (only-in racket/fixnum fxvector?)
         (only-in racket/future fsemaphore?)
         (only-in '#%place place? place-channel?))

(provide (all-defined-out)
         (except-out (all-from-out "base-abbrev.rkt" "match-expanders.rkt") make-arr))

;; Convenient constructors
(define -App make-App)
(define -mpair make-MPair)
(define (-Param t1 [t2 t1]) (make-Param t1 t2))
(define -box make-Box)
(define -channel make-Channel)
(define -async-channel make-Async-Channel)
(define -thread-cell make-ThreadCell)
(define -Promise make-Promise)
(define -set make-Set)
(define -vec make-Vector)
(define (-vec* . ts) (make-HeterogeneousVector ts))
(define -future make-Future)
(define -evt make-Evt)
(define -weak-box make-Weak-Box)
(define -inst make-Instance)
(define (-prefab key . types)
  (make-Prefab (normalize-prefab-key key (length types)) types))
(define -unit make-Unit)
(define -signature make-Signature)

(define (-seq . args) (make-Sequence args))

(define (one-of/c . args)
  (apply Un (map -val args)))

(define (-opt t) (Un (-val #f) t))

(define (-ne-lst t) (-pair t (-lst t)))

;; Convenient constructor for Values
;; (wraps arg types with Result)
(define/cond-contract (-values args)
  (c:-> (c:listof Type?) (c:or/c Type? Values?))
  (match args
    [_ (make-Values (for/list ([i (in-list args)]) (-result i)))]))

;; Convenient constructor for ValuesDots
;; (wraps arg types with Result)
(define/cond-contract (-values-dots args dty dbound)
  (c:-> (c:listof Type?) Type? (c:or/c symbol? c:natural-number/c)
        ValuesDots?)
  (make-ValuesDots (for/list ([i (in-list args)]) (-result i))
                   dty dbound))

;; Basic types
(define -Listof (-poly (list-elem) (make-Listof list-elem)))
(define/decl -Regexp (Un -PRegexp -Base-Regexp))
(define/decl -Byte-Regexp (Un -Byte-Base-Regexp -Byte-PRegexp))
(define/decl -Pattern (Un -Bytes -Regexp -Byte-Regexp -String))
(define/decl -Module-Path
  (-mu X
       (Un -Symbol -String -Path
           (-lst* (-val 'quote) -Symbol)
           (-lst* (-val 'lib) -String)
           (-lst* (-val 'file) -String)
           (-pair (-val 'planet)
                  (Un (-lst* -Symbol)
                      (-lst* -String)
                      (-lst* -String
                             (-lst*
                              -String -String
                              #:tail (make-Listof
                                      (Un -Nat
                                          (-lst* (Un -Nat (one-of/c '= '+ '-))
                                                 -Nat)))))))
           (-lst* (-val 'submod) X
                  #:tail (-lst (Un -Symbol (-val "..")))))))
(define/decl -Compiled-Expression (Un -Compiled-Module-Expression -Compiled-Non-Module-Expression))
;; in the type (-Syntax t), t is the type of the result of syntax-e, not syntax->datum
(define -Syntax make-Syntax)
(define/decl In-Syntax
  (-mu e
       (Un -Null -Boolean -Symbol -String -Keyword -Char -Number
           (make-Vector (-Syntax e))
           (make-Box (-Syntax e))
           (make-Listof (-Syntax e))
           (-pair (-Syntax e) (-Syntax e)))))
(define/decl Any-Syntax (-Syntax In-Syntax))
(define (-Sexpof t)
  (-mu sexp
       (Un -Null
           -Number -Boolean -Symbol -String -Keyword -Char
           (-pair sexp sexp)
           (make-Vector sexp)
           (make-Box sexp)
           t)))
(define/decl -Flat
  (-mu flat
       (Un -Null -Number -Boolean -Symbol -String -Keyword -Char
           (-pair flat flat))))
(define/decl -Sexp (-Sexpof (Un)))
(define Syntax-Sexp (-Sexpof Any-Syntax))
(define Ident (-Syntax -Symbol))
(define -HT make-Hashtable)
(define/decl -Port (Un -Output-Port -Input-Port))
(define/decl -SomeSystemPath (Un -Path -OtherSystemPath))
(define/decl -Pathlike (Un -String -Path))
(define/decl -SomeSystemPathlike (Un -String -SomeSystemPath))
(define/decl -Pathlike* (Un -String -Path (-val 'up) (-val 'same)))
(define/decl -SomeSystemPathlike*
  (Un -String -SomeSystemPath(-val 'up) (-val 'same)))
(define/decl -PathConventionType (Un (-val 'unix) (-val 'windows)))
(define/decl -Log-Level (one-of/c 'fatal 'error 'warning 'info 'debug))
(define/decl -Place-Channel (Un -Place -Base-Place-Channel))

;; note, these are number? #f
(define/decl -ExtFlonumZero (Un -ExtFlonumPosZero -ExtFlonumNegZero -ExtFlonumNan))
(define/decl -PosExtFlonum (Un -PosExtFlonumNoNan -ExtFlonumNan))
(define/decl -NonNegExtFlonum (Un -PosExtFlonum -ExtFlonumZero))
(define/decl -NegExtFlonum (Un -NegExtFlonumNoNan -ExtFlonumNan))
(define/decl -NonPosExtFlonum (Un -NegExtFlonum -ExtFlonumZero))
(define/decl -ExtFlonum (Un -NegExtFlonumNoNan -ExtFlonumNegZero -ExtFlonumPosZero -PosExtFlonumNoNan -ExtFlonumNan))

;; Type alias names
(define (-struct-name name)
  (make-Name name 0 #t))

;; Structs
(define (-struct name parent flds [proc #f] [poly #f] [pred #'dummy])
  (make-Struct name parent flds proc poly pred))

;; Function type constructors
(define/decl top-func (make-Function (list)))

(define (asym-pred dom rng prop)
  (make-Function (list (make-arr* (list dom) rng #:props prop))))

(define/cond-contract make-pred-ty
  (c:case-> (c:-> Type? Type?)
            (c:-> (c:listof Type?) Type? Type? Type?)
            (c:-> (c:listof Type?) Type? Type? Object? Type?))
  (case-lambda
    [(in out t o)
     (->* in out : (-PS (-is-type o t) (-not-type o t)))]
    [(in out t)
     (make-pred-ty in out t (make-Path null (cons 0 0)))]
    [(t)
     (make-pred-ty (list Univ) -Boolean t (make-Path null (cons 0 0)))]))

(define/decl -true-propset (-PS -tt -ff))
(define/decl -false-propset (-PS -ff -tt))

(define (opt-fn args opt-args result #:rest [rest #f] #:kws [kws null])
  (apply cl->* (for/list ([i (in-range (add1 (length opt-args)))])
                 (make-Function (list (make-arr* (append args (take opt-args i)) result
                                                 #:rest rest #:kws kws))))))

(define-syntax-rule (->opt args ... [opt ...] res)
  (opt-fn (list args ...) (list opt ...) res))

;; from define-new-subtype
(define (-Distinction name sym ty)
  (make-Distinction name sym ty))

;; class utilities

(begin-for-syntax
 (define-syntax-class names+types
   #:attributes (data)
   (pattern [(name:id type) ...]
            #:with data #'(list (list (quote name) type) ...)))

 (define-syntax-class names+types+opt
   #:attributes (data no-opts)
   (pattern [(name:id type opt?) ...]
            #:with data #'(list (list (quote name) type opt?) ...)
            #:with no-opts #'(list (list (quote name) type) ...)))

 (define-splicing-syntax-class -class-clause
   #:attributes (inits fields methods augments)
   (pattern (~seq #:init sub-clauses:names+types+opt)
            #:with inits #'sub-clauses.data
            #:with fields #'null
            #:with methods #'null
            #:with augments #'null)
   (pattern (~seq #:init-field sub-clauses:names+types+opt)
            #:with inits #'sub-clauses.data
            #:with fields #'sub-clauses.no-opts
            #:with methods #'null
            #:with augments #'null)
   (pattern (~seq #:method sub-clauses:names+types)
            #:with inits #'null
            #:with fields #'null
            #:with methods #'sub-clauses.data
            #:with augments #'null)
   (pattern (~seq #:field sub-clauses:names+types)
            #:with inits #'null
            #:with fields #'sub-clauses.data
            #:with methods #'null
            #:with augments #'null)
   (pattern (~seq #:augment sub-clauses:names+types)
            #:with inits #'null
            #:with fields #'null
            #:with methods #'null
            #:with augments #'sub-clauses.data)))

(define-syntax (-class stx)
  (syntax-parse stx
    [(_ (~or (~optional (~seq #:row var:expr)
                        #:defaults ([var #'#f]))
             ?clause:-class-clause) ...)
     #'(make-Class
        var
        (append ?clause.inits ...)
        (append ?clause.fields ...)
        (append ?clause.methods ...)
        (append ?clause.augments ...)
        #f)]))

(define-syntax-rule (-object . ?clauses)
  (make-Instance (-class . ?clauses)))

