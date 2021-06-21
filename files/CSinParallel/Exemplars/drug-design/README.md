# drug-design
CSinParallel drug design exemplar code for various platforms.  

CSinParallel is an NSF-funded project to support instructors seeking to add Parallel and Distributed Computing (PDC) to their undergraduate computer science courses.  The csinparallel.org website provides free resources towards this goal, including a number of teaching modules for inserting a few days of instruction on a PDC topic to a given course.

The Drug Design Exemplar CSinParallel module https://csinparallel.org/csinparallel/modules/drugDesign.html considers the application of scoring candidate drug "ligands" against a protein, using a simple representative scoring computation.  Implementations are provided for numerous PDC platforms based on a map-reduce structural pattern.  The range of platforms enables this module to be incorporated in a wide variety of course or extracurricular contexts.  

This repository contains the collection of code examples, including implementations beyond those described currently in the module.  Even without students examining the code itself, we have found them useful as "black boxes" for exploring the nature of PDC computation in elementary courses and in workshop presentations, where participants encounter issues such as speedup vs. number of processing elements, the effects of variable length cpu-intensive computational tasks, scheduling of parallel tasks, etc.  

A simple example Makefile is provided for compiling the various code versions (where appropriate). 
