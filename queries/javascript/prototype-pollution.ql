/**
 * @name Prototype pollution
 * @description Using _.merge() or Object.assign() with user-controlled input
 *              can lead to prototype pollution attacks.
 * @kind problem
 * @problem.severity error
 * @id js/globomantics/prototype-pollution
 * @tags security
 *       external/cwe/cwe-1321
 */

import javascript

from CallExpr call
where
  (
    // _.merge(target, req.body)
    exists(DotExpr dot |
      call.getCallee() = dot and
      dot.getBase().(VarAccess).getName() = "_" and
      dot.getPropertyName() = "merge"
    )
    or
    // Object.assign({}, target, req.body)
    exists(DotExpr dot |
      call.getCallee() = dot and
      dot.getBase().(VarAccess).getName() = "Object" and
      dot.getPropertyName() = "assign"
    )
  )
select call, "Potential prototype pollution: avoid merging user input into objects without sanitization (CWE-1321)."
