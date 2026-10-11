#import "../worksheet.typ": worksheet, question, part, task, answers, answer, solutions, solution
#import "@preview/simple-plot:1.1.0": plot

#show: worksheet.with(
  title: [Example],
  page-numbers: true,
)

= Solving linear equations

Use inverse operations to solve each equation. Show your working in the space provided.

== One-step equations

#question(columns: 3, working: 3, parts: (
  part[$x + 7 = 15$], part[$y - 9 = 4$], part[$5a = 35$],
  part[$b / 4 = 6$], part[$m + 3 = -2$], part[$-3n = 18$],
))[Solve each equation.]

#question(columns: 2, working: 3, tasks: (
  task[State the inverse operation needed.],
  task[Solve the equation and check by substitution.],
), parts: (
  part[$p - 6 = 11$], part[$q / 5 = 3$],
))[For each of the following:]

== Two-step equations

#question(columns: 3, working: 4, parts: (
  part[$2x + 5 = 19$], part[$3y - 4 = 20$], part[$a / 4 + 3 = 8$],
  part[$5b + 2 = -13$], part[$12 - 2m = 4$], part[$n / 3 - 7 = -2$],
))[]

#question(working: 4, marks: 3)[Solve $7 - x / 2 = 1$. Check your solution by substituting it into the original equation.]

#pagebreak()

=== Explain your reasoning

#question(columns: 2, working: 3, parts: (
  part[Alex says that the solution of $3x + 6 = 21$ is $x = 9$. Explain the error, then find the correct solution.],
  part[Sam solves $x / 4 - 2 = 5$ by adding 2 to both sides first.

Explain why this is a useful first step, then finish the solution.],
))[Read each part carefully.]

== Equations with brackets and equations with pronumerals on both sides

#question(columns: 2, working: 4, parts: (
  part[$3(x + 2) = 21$], part[$2(y - 4) = 10$],
  part[$5a + 4 = 2a + 19$], part[$7b - 8 = 3b + 12$],
  part[$2(m + 3) = m + 11$], part[$3(n - 2) = 2n + 1$],
))[Expand the brackets where needed, then collect like terms and solve.]

#question(columns: 1, working: 4, parts: (
  part(marks: 1)[$2(x + 5) = 26$],
  part(parts: (
    task(marks: 2)[Expand the brackets and solve $4(y - 1) = 2y + 10$.],
    task(marks: 1)[Check your solution by substitution.],
  ))[],
))[Show a clear sequence of equivalent equations.]

== Equations from words

#question(working: 4, marks: 3)[Three more than twice a number is 27. Let $n$ represent the number. Write an equation and solve it to find the number.]

#question(columns: 2, working: 4, parts: (
  part[Five less than three times a number is 16. ],
  part[A number divided by four, then increased by six, gives 11.],
))[Translate each statement into an equation using $n$ for the number and solve the equation to find the number.]

== Practical contexts

#question(working: 5, marks: 4)[A bike hire shop charges a fixed fee of \$8 plus \$6 per hour. Mia pays \$38.

Let $h$ be the number of hours. Write and solve an equation to find how long Mia hired the bike.]

#question(working: 3)[A rectangle has width $x$ cm and length $(x + 3)$ cm. Its perimeter is 30 cm. Write an equation and find both dimensions.

#v(12pt, weak: true)
#align(center)[#pad(top: 14pt)[
  #box(width: 5cm, height: 2cm, stroke: 0.5pt)[
    #place(top + center, dy: -14pt)[$(x + 3)$ cm]
    #place(right + horizon, dx: 38pt)[$x$ cm]
  ]
]]
]

#question(working: 2)[A delivery service charges a fixed booking fee and \$2 per kilometre. Use the table to find the booking fee, then find the distance travelled when the total cost is \$23.

#v(12pt, weak: true)
#align(center, table(columns: (auto, auto, auto, auto), align: center,
  [Distance (km)], [2], [4], [6],
  [Total cost (\$)], [11], [15], [19],
))
]

#question(working: 2)[The graph shows the cost $C$ dollars of hiring equipment for $t$ hours. The relation is $C = 4t + 8$. Use an equation to find the time when the cost is \$24, then check it on the graph.

#v(12pt, weak: true)
#align(center, plot(
  width: 5cm, height: 3cm,
  xmin: 0, xmax: 5,
  ymin: 0, ymax: 30,
  xtick-step: 1, ytick-step: 10,
  xlabel: [$t$ (hours)], xlabel-pos: "center", xlabel-offset: (0, -0.6),
  ylabel: [$C$ (dollars)], ylabel-anchor: "south-west", ylabel-offset: (0, 0.15),
  tick-label-size: 12pt, axis-label-size: 12pt,
  style: (axis: (stroke: black + 0.5pt), ticks: (stroke: black + 0.5pt)),
  (fn: t => 4 * t + 8, stroke: black + 0.8pt),
))
]

#answers[
  #answer(columns: 3, parts: (part[$x=8$], part[$y=13$], part[$a=7$], part[$b=24$], part[$m=-5$], part[$n=-6$]))[]
  #answer(columns: 2, parts: (
    part(parts: (task[Add 6.], task[$p=17$; $17-6=11$.]))[],
    part(parts: (task[Multiply by 5.], task[$q=15$; $15/5=3$.]))[],
  ))[]
  #answer(columns: 3, parts: (part[$x=7$], part[$y=8$], part[$a=20$], part[$b=-3$], part[$m=4$], part[$n=15$]))[]
  #answer[$x=12$.]
  #answer(columns: 2, parts: (part[Subtract 6 before dividing by 3; $x=5$.], part[Adding 2 undoes subtracting 2; $x=28$.]))[]
  #answer(columns: 3, parts: (part[$x=5$], part[$y=9$], part[$a=5$], part[$b=5$], part[$m=5$], part[$n=7$]))[]
  #answer(parts: (part[$x=8$], part(parts: (task[$y=7$], task[Both sides equal 24.]))[]))[]
  #answer[$2n+3=27$; $n=12$.]
  #answer(columns: 2, parts: (part[$3n-5=16$; $n=7$.], part[$n/4+6=11$; $n=20$.]))[]
  #answer[$8+6h=38$; $h=5$. The hire lasted 5 hours.]
  #answer[$2x+2(x+3)=30$; $x=6$. Width 6 cm; length 9 cm.]
  #answer[Booking fee \$7; $7+2d=23$; $d=8$ km.]
  #answer[$4t+8=24$; $t=4$ hours.]
]

#solutions[
  // Keep worked equations at the content inset, with one step per line.
  #show math.equation.where(block: true): set align(left)
  #show math.equation.where(block: true): set par(leading: 4pt)
  #show math.equation.where(block: true): set block(above: 6pt, below: 6pt)

  #solution(columns: 2, parts: (
    part[
      $ x + 7 &= 15 \
        x &= 15 - 7 \
        x &= 8 $
    ],
    part[
      $ y - 9 &= 4 \
        y &= 4 + 9 \
        y &= 13 $
    ],
    part[
      $ 5a &= 35 \
        a &= 35 / 5 \
        a &= 7 $
    ],
    part[
      $ b / 4 &= 6 \
        b &= 6 times 4 \
        b &= 24 $
    ],
    part[
      $ m + 3 &= -2 \
        m &= -2 - 3 \
        m &= -5 $
    ],
    part[
      $ -3n &= 18 \
        n &= 18 / (-3) \
        n &= -6 $
    ],
  ))[]
  #solution(parts: (
    part(parts: (
      task[Add 6 to both sides to undo subtracting 6.],
      task[
        $ p - 6 &= 11 \
          p &= 11 + 6 \
          p &= 17 $
        Check: $17 - 6 = 11$, which equals the right-hand side.
      ],
    ))[],
    part(parts: (
      task[Multiply both sides by 5 to undo dividing by 5.],
      task[
        $ q / 5 &= 3 \
          q &= 3 times 5 \
          q &= 15 $
        Check: $15 / 5 = 3$, which equals the right-hand side.
      ],
    ))[],
  ))[]

  #solution(columns: 2, parts: (
    part[
      $ 2x + 5 &= 19 \
        2x &= 14 \
        x &= 7 $
    ],
    part[
      $ 3y - 4 &= 20 \
        3y &= 24 \
        y &= 8 $
    ],
    part[
      $ a / 4 + 3 &= 8 \
        a / 4 &= 5 \
        a &= 20 $
    ],
    part[
      $ 5b + 2 &= -13 \
        5b &= -15 \
        b &= -3 $
    ],
    part[
      $ 12 - 2m &= 4 \
        -2m &= -8 \
        m &= 4 $
    ],
    part[
      $ n / 3 - 7 &= -2 \
        n / 3 &= 5 \
        n &= 15 $
    ],
  ))[]
  #solution[
    $ 7 - x / 2 &= 1 \
      -x / 2 &= -6 \
      x &= 12 $
    Check: $7 - 12 / 2 = 7 - 6 = 1$, which equals the right-hand side.
  ]
  #pagebreak()
  #solution(parts: (
    part[
      Substituting Alex's value gives $3 times 9 + 6 = 33$, not 21, so $x = 9$ is incorrect.
      To isolate $x$, first subtract 6 from both sides, then divide both sides by 3.
      $ 3x + 6 &= 21 \
        3x &= 15 \
        x &= 5 $
    ],
    part[
      Adding 2 to both sides undoes subtracting 2 and leaves $x / 4$ on its own.
      Then multiply both sides by 4.
      $ x / 4 - 2 &= 5 \
        x / 4 &= 7 \
        x &= 28 $
    ],
  ))[]

  #solution(columns: 2, parts: (
    part[
      $ 3(x + 2) &= 21 \
        3x + 6 &= 21 \
        3x &= 15 \
        x &= 5 $
    ],
    part[
      $ 2(y - 4) &= 10 \
        2y - 8 &= 10 \
        2y &= 18 \
        y &= 9 $
    ],
    part[
      $ 5a + 4 &= 2a + 19 \
        3a + 4 &= 19 \
        3a &= 15 \
        a &= 5 $
    ],
    part[
      $ 7b - 8 &= 3b + 12 \
        4b - 8 &= 12 \
        4b &= 20 \
        b &= 5 $
    ],
    part[
      $ 2(m + 3) &= m + 11 \
        2m + 6 &= m + 11 \
        m + 6 &= 11 \
        m &= 5 $
    ],
    part[
      $ 3(n - 2) &= 2n + 1 \
        3n - 6 &= 2n + 1 \
        n - 6 &= 1 \
        n &= 7 $
    ],
  ))[]
  #solution(parts: (
    part[
      $ 2(x + 5) &= 26 \
        x + 5 &= 13 \
        x &= 8 $
    ],
    part(parts: (
      task[
        $ 4(y - 1) &= 2y + 10 \
          4y - 4 &= 2y + 10 \
          2y - 4 &= 10 \
          2y &= 14 \
          y &= 7 $
      ],
      task[
        Substitute $y = 7$ into each side of the original equation.
        $ "Left-hand side" &= 4(7 - 1) = 24 \
          "Right-hand side" &= 2 times 7 + 10 = 24 $
        Both sides equal 24, so $y = 7$ is correct.
      ],
    ))[],
  ))[]

  #pagebreak()
  #solution[
    Twice the number is $2n$, and three more gives $2n + 3$.
    $ 2n + 3 &= 27 \
      2n &= 24 \
      n &= 12 $
    The number is 12.
  ]
  #solution(columns: 2, parts: (
    part[
      $ 3n - 5 &= 16 \
        3n &= 21 \
        n &= 7 $
      The number is 7.
    ],
    part[
      $ n / 4 + 6 &= 11 \
        n / 4 &= 5 \
        n &= 20 $
      The number is 20.
    ],
  ))[]
  #solution[
    The total cost is the fixed fee plus the hourly charge.
    $ 8 + 6h &= 38 \
      6h &= 30 \
      h &= 5 $
    Mia hired the bike for 5 hours.
  ]
  #solution[
    The perimeter is twice the width plus twice the length.
    $ 2x + 2(x + 3) &= 30 \
      2x + 2x + 6 &= 30 \
      4x + 6 &= 30 \
      4x &= 24 \
      x &= 6 $
    The width is 6 cm. The length is $(6 + 3)$ cm $= 9$ cm.

    Check: the perimeter is $(2 times 6 + 2 times 9)$ cm $= 30$ cm.
  ]
  #solution[
    At 2 km, the distance charge is $2 times 2 = 4$ dollars.
    The booking fee is therefore $11 - 4 = 7$ dollars.

    Let $d$ be the distance travelled in kilometres. For a total cost of \$23:
    $ 7 + 2d &= 23 \
      2d &= 16 \
      d &= 8 $
    The distance travelled is 8 km.
  ]
  #solution[
    Substitute $C = 24$ into $C = 4t + 8$.
    $ 4t + 8 &= 24 \
      4t &= 16 \
      t &= 4 $
    The hire time is 4 hours. To check on the graph, read across from $C = 24$
    to the line, then down to the time axis: $t = 4$.
  ]
]
