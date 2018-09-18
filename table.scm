;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File: table.scm 
; Date: Sep 9, 2018
; Author: Xue Cheng 
; Email: xuecheng@nuaa.edu.cn
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;; USAGE ;;;;;;;;;;;;;;;;;;;;;;;;;
; # Run Fluent in Background:
;   fluent 3ddp -t24 -g -i table.scm > table.log 2>&1 &  
; # Or use GNU screen:
;   screen -S flu
;   fluent 3ddp -t24 -g -i table.scm
;;;;;;;;;;;;;;;;;;;;;;;;; USAGE ;;;;;;;;;;;;;;;;;;;;;;;;;



; test flag, #t: only display commands
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
; pressure-far-field 
;   turb: turbulence model, used to set
;   name: bc name
;   p:    gauge pressure
;   ma:   Mach number
;   t:    temperature
;   vx, vy, vz:  flow direction
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
; set Operating Pressure
(tis (format #f "de oc op ~a" 89876.3))
; set reference area
(ref-area 2.5)
; set reference length
(ref-len 0.8)
; set CFL number
(set-cfl 5)
; residual converge criterion
(tis "so monit res conv-crit 0.00001 0.00001 0.00001 0.00001 0.00001")
; dones not plot residual
(tis "so monit res plot no")
; print residual
(tis "so monit res print y")
(define aoas (list -4 -2 0 2 4 6 8 10 12 14 16))
(define turbs (list "s-a" "kw-sst" "ke-realiz"))
(for-each (lambda (turb) 
    (for-each (lambda (aoa) 
        (let ((vx (cos (radians aoa))) (vy (sin (radians aoa))))
            (set-turb turb)
            ; set pressure-far-field "far"
            (set-far turb "far" 0 0.1783405 281.651 vx vy 0)
            (ref-far "far")
            (tis (format #f "so mo force lc y wall ,  y n n n ~a ~a 0" (- vy) vx))
            (tis (format #f "so mo force dc y wall ,  y n n n ~a ~a 0" (- vx) (- vy)))
            (if (= (car aoas) aoa) 
                (begin 
                    ; initialize from "far"
                    (tis "so init cd pff far")
                    (tis "so init initialize-flow")
                    ; calc 4000 iters for first run
                    (iter 4000)
                ) ;#t
                (iter 3000) ;#f
            )
            ; report wall forces and moments
            ;   wall force:
            ;   re fo wf y <axis_x> <axis_y> <axis_z> y <file>
            ;   wall moment:
            ;   re fo wm y <ref_x> <ref_y> <ref_z> <axis_x> <axis_y> <axis_z> y <file>
            (tis (format #f "re fo wf y ~a ~a 0 y Cd_~a_~a.txt" (- vx) (- vy) aoa turb))
            (tis (format #f "re fo wf y ~a ~a 0 y Cl_~a_~a.txt" (- vy) vx aoa turb))
            (tis (format #f "re fo wm y 1.3292731 0 0 0 0 1 y Cm_~a_~a.txt" aoa turb))
            (tis (format #f "f wc ./base_~a_~a.cas" aoa turb))
            (tis (format #f "f wd ./base_~a_~a.dat" aoa turb))
        ))
    aoas))
turbs)
(tis "exit yes")
