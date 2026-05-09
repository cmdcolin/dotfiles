
In typescript, avoid using type `any` and typecasts, aim for correctness


Avoid "early return" style code, just nest if statements or use ternaries

When faced with a bug, try to add more debug logging or evaluate the context of the issue, and try to prove a hypothesis, instead of making simple workaround fixes

Avoid numbering lists in markdown or tests because order of things often change and renumbering is cumbersome

Be very cautious when reaching for useRef and useEffect because it is often a sign of non-idiomatic overcomplicated react

Usages of || and ?? are often code smells that need to be carefully considered if they are truly necessary. Many of these usages outside of just providing simple config fallbacks could be more reliably fixed by avoiding the undefined state entirely

You can use lint with --cache and --fix to help apply autofixes

Minimize wordiness in all writing and comments. When adding new code, make the code self explanatory so it barely needs commenting.

Do not run git stash, multiple agents are often working in a single repo at a time

Be careful with passing direct function props like onClick={handleClose}. prefer onClick={()=>handleClose()} to help explicitly ensure that no parameters or explicit parameters are passed
