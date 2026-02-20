/**
 * @name Weak cryptographic hash function
 * @description Using MD5 or SHA1 is cryptographically broken and should not be
 *              used for security-sensitive operations.
 * @kind problem
 * @problem.severity warning
 * @id js/globomantics/weak-crypto
 * @tags security
 *       external/cwe/cwe-327
 */

import javascript

from MethodCallExpr call, string algo
where
  call.getMethodName() = "createHash" and
  algo = call.getArgument(0).(StringLiteral).getValue() and
  (algo = "md5" or algo = "sha1")
select call, "Weak hash algorithm '" + algo + "' detected. Use SHA-256 or stronger (CWE-327)."
