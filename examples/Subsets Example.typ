#import "../worksheet.typ": worksheet, question, part, task, answers, answer, solutions, solution, line-height, label-width
#import "@preview/simple-plot:1.1.0": plot
#show: worksheet.with(title: [Subsets Example])

// Supply the spoken form alongside the typeset equation in this accessibility trial.
#let eq(spoken, formula) = math.equation(alt: spoken, formula.body)

#question(columns: 2, parts: (
  part(parts: (
    task[Name the inverse operation.], task[Apply it to both sides.],
    task[State the solution.], task[Check by substitution.],
  ))[#eq("x plus one equals three", $x+1=3$)],
  part[#eq("x plus two equals five", $x+2=5$)],
  part[#eq("x plus three equals seven", $x+3=7$)],
  part[#eq("x plus four equals nine", $x+4=9$)],
  part[#eq("x plus five equals eleven", $x+5=11$)],
))[Solve.]

// Each grid cell starts a whole question. Source order is also reading order.
#grid(columns: (1fr, 1fr), column-gutter: label-width, align: top,
  question(working: 2)[Use the table to find the input that gives an output of 8.
    #v(line-height)
    #table(columns: 2, align: center,
      table.header([Input], [Output]),
      [3], [6], [4], [8], [5], [10],
    )
  ],
  question(working: 2)[Use the graph to find the input that gives an output of 15.
    #v(line-height)
    #let description = "The line joins (0, 0) and (6, 18). Each grid square is 1 input unit wide and 3 output units high."
    // Keep the tick labels out of the reading order. The same description is
    // available as figure alt text and as ordinary text directly below the plot.
    #figure(kind: image, alt: description, pdf.artifact(plot(
      width: 5cm, height: 3.5cm, xmin: 0, xmax: 6, ymin: 0, ymax: 18,
      tick-label-size: 12pt, axis-label-size: 12pt,
      xtick-step: 1, ytick-step: 3, show-grid: "major", hide-crossed-tick-labels: false,
      origin-label-anchor: "north-east", origin-label-offset: (-0.12, -0.12),
      xlabel: [Input], xlabel-pos: "center", xlabel-offset: (0, -0.55),
      ylabel: [Output], ylabel-anchor: "south-west", ylabel-offset: (0, 0.15),
      (fn: x => 3 * x, stroke: black + 0.8pt),
    )))
    #v(line-height)
    #description
  ],
)

#question[#eq("four x equals twenty-four", $4x=24$)]
#question[#eq("five x equals thirty-five", $5x=35$)]
#question[#eq("six x equals forty-eight", $6x=48$)]

#answers[
  #answer(parts: (
    part(parts: (task(ref: "iii")[#eq("x equals two", $x=2$)],))[],
    part(ref: "d")[#eq("x equals five", $x=5$)],
    part[#eq("x equals six", $x=6$)],
  ))[]
  #answer[The input is 4.]
  #answer(ref: 5)[#eq("x equals seven", $x=7$)]
  #answer[#eq("x equals eight", $x=8$)]
]
#solutions[
  #solution(parts: (part(parts: (
    task[Subtract 1.],
    task(ref: "iii")[#eq("x equals two", $x=2$)],
    task[Check by substituting 2. #eq("Two plus one equals three.", $2+1=3$)],
  ))[],))[]
  #solution(ref: 5)[#eq("Five x equals thirty-five, so x equals seven.", $5x=35 => x=7$)]
  #solution[#eq("Six x equals forty-eight, so x equals eight.", $6x=48 => x=8$)]
]
