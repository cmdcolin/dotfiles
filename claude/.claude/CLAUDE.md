use very minimal or no comments

When adding new code, make the code self explanatory so it barely needs
commenting, do not add comments just because code surrounding where you are
working uses comments

In typescript, avoid using type `any` and typecasts, aim for correctness

prefer implicit return types over explicit return types in typescript

Avoid "early return" style code, just nest if statements or use ternaries

Avoid the use of global variables

Usages of || and ?? are often code smells that need to be carefully considered
if they are truly necessary. Many of these usages outside of just providing
simple config fallbacks could be more reliably fixed by avoiding the undefined
state entirely

when storing the error in a react useState, store the actual error object and
stringify it at point of use

Be very cautious when reaching for useRef and useEffect because it is often a
sign of non-idiomatic overcomplicated react

Be careful with passing direct function props like onClick={handleClose}. prefer
onClick={()=>handleClose()} to help explicitly ensure that no parameters or
explicit parameters are passed

When faced with a bug, try to add more debug logging or evaluate the context of
the issue, and try to prove a hypothesis, instead of making simple workaround
fixes

do not remove debug logging until we confirm we are done with the issue

Avoid numbering lists in markdown or tests because order of things often change
and renumbering is cumbersome

You can use lint with --cache and --fix to help apply autofixes

in jbrowse-components, whenever we change a wgsl shader, we should use our
compile-shader-utils to recompile it to glsl

Please do not open up PR automatically on github for me

Don't open new branches for work, just commit to current branch

Do not run git stash, multiple agents are often working in a single repo at a
time

Always commit with an explicit pathspec (`git commit -- <paths>`), never
`git add` plus a bare `git commit`. Another agent may be working in the same
worktree, and the git index is shared, so a bare commit silently sweeps up
whatever they have staged (and theirs sweeps up yours)
