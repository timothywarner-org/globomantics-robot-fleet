/**
 * @name Insecure randomness
 * @description Math.random() does not produce cryptographically secure values
 *              and must not be used for tokens, secrets, or security decisions.
 * @kind problem
 * @problem.severity warning
 * @id js/globomantics/insecure-randomness
 * @tags security
 *       external/cwe/cwe-330
 */

import javascript

from MethodCallExpr call
where
  call.getMethodName() = "random" and
  call.getReceiver().(VarAccess).getName() = "Math"
select call, "Math.random() is not cryptographically secure. Use crypto.randomBytes() instead (CWE-330)."
