.. _tuto_artn_blocks:


************************************
The pARTn steps, and block structure
************************************


A single ARTn step is composed of 3 procedures:

 1) determine the push direction;
 2) push system along this direction;
 3) perform relaxation constrained in the direction perpendicular to the push.

These steps are repeated until a saddle is reached, at which point the adjacent minima can be found by regular minimization.

In order to simplify navigation, the idea of algorithm blocks is introduced.
Thus, ARTn is composed of the following blocks:

 - initial push ("push init");
 - perpendicular relaxation ("perp relax");
 - computation of the eigenvector ("lanczos");
 - push with eigenvector ("eigen push");
 - push from saddle ("push over");
 - relaxation to minima ("relax");

