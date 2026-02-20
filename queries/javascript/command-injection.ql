/**
 * @name Command injection via execSync
 * @description Calling execSync with user-controlled input enables OS command injection.
 * @kind problem
 * @problem.severity error
 * @id js/globomantics/command-injection
 * @tags security
 *       external/cwe/cwe-078
 */

import javascript

from CallExpr call
where call.getCalleeName() = "execSync"
select call, "Dangerous execSync() call detected. Use parameterized commands or input validation (CWE-078)."
