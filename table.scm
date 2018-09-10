;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File: table.scm 
; Date: Sep 9, 2018
; Author: Xue Cheng 
; Email: xuecheng@nuaa.edu.cn
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; test flag
(define test_run #f)
; deg -> rad
(define radians (lambda (deg) (* (/ deg 45) (atan 1))))
(define tis (if test_run display ti-menu-load-string))
(define mesh-scale 
    (lambda (sx sy sz) (tis (format #f "mesh scale ~a ~a ~a" sx sy sz))))
; dbe=density-based-explicit 
; dbi=density-based-implicit
; pb=pressure-based
(define set-eq 
    (lambda (t) (tis (format #f "de mo solver ~a y" t))))
; s-a 
; ke-stand ke-rng ke-realiz
; kw-stand kw-bsl kw-sst
(define set-turb 
    (lambda (t) (tis (format #f "de mo visc ~a y" t))))

(define set-far(lambda (turb name p ma t vx vy vz)
    (tis (format #f 
        (if (string=? turb "s-a")
            "de bc pff ~a no ~a no ~a no ~a yes no ~a no ~a no ~a no no yes no 10" 
            "de bc pff ~a no ~a no ~a no ~a yes no ~a no ~a no ~a no no yes  5 10")
        name p ma t vx vy vz))))

(define ref-far (lambda (name) (tis (format #f "re rv c pff ~a" name))))
(define ref-area (lambda (s) (tis (format #f "re rv area ~a" s))))
(define ref-len (lambda (l) (tis (format #f "re rv len ~a" l))))
(define set-cfl (lambda (cfl) (tis (format #f "so set cn ~a" cfl))))

(define iter (lambda (count) (tis (format #f "so it ~a" count))))
(tis "f rc ./base.cas") ; /file/read-case
(mesh-scale 0.001 0.001 0.001)
(tis "mesh chech") ; /mesh/check
(set-eq "dbi") ; set control eq.
(tis "de mo steady y")
(tis "de mo energy y")
; Ideal gas & Sutherland law
(tis "de ma cc air air y ideal-gas n n y sutherland three-coefficient-method 1.716e-05 273.11 110.56 n n n")
(tis (format #f "de oc op ~a" 89876.3))
(ref-area 1.385)
(ref-len 0.581)
(set-cfl 5)
;residual
(tis "so monit res conv-crit 0.00001 0.00001 0.00001 0.00001 0.00001")
(tis "so monit res plot no")
(tis "so monit res print y")
(define aoas (list -4 -2 0 2 4 6 8 10 12 14 16))
(define turbs (list "s-a" "kw-sst" "ke-realiz"))
(for-each (lambda (turb) 
    (for-each (lambda (aoa) 
        (let ((vx (cos (radians aoa))) (vy (sin (radians aoa))))
            (set-turb turb)
            (set-far turb "far" 0 0.1783405 281.651 vx vy 0)
            (ref-far "far")
            (tis (format #f "so mo force lc y wall ,  y n n n ~a ~a 0" (- vy) vx))
            (tis (format #f "so mo force dc y wall ,  y n n n ~a ~a 0" (- vx) (- vy)))
            (if (= (car aoas) aoa) 
                (begin 
                    (tis "so init cd pff far")
                    (tis "so init initialize-flow")
                    (iter 4000)
                ) ;#t
                (iter 3000) ;#f
            )
            (tis (format #f "re fo wf y ~a ~a 0 y Cd_~a_~a.txt" (- vx) (- vy) aoa turb))
            (tis (format #f "re fo wf y ~a ~a 0 y Cl_~a_~a.txt" (- vy) vx aoa turb))
            (tis (format #f "re fo wm y 1.3292731 0 0 0 0 1 y Cm_~a_~a.txt" aoa turb))
            (tis (format #f "f wc ./base_~a_~a.cas" aoa turb))
            (tis (format #f "f wd ./base_~a_~a.dat" aoa turb))
        ))
    aoas))
turbs)
(tis "exit yes")
