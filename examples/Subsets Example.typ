#import "../worksheet.typ": worksheet, question, part, task, answers, answer, solutions, solution
#show: worksheet.with(title: [Subsets Example], page-numbers: false)
#question(parts: (part[$x+1=3$], part[$x+2=5$], part[$x+3=7$], part[$x+4=9$], part[$x+5=11$]), columns: 2, working: 0)[Solve.]
#question(working: 0)[$2x=8$]
#question(working: 0)[$3x=15$]
#question(working: 0)[$4x=24$]
#question(working: 0)[$5x=35$]
#question(working: 0)[$6x=48$]

#answers[
  #answer(parts: (part[$x=2$], part(ref: "d")[$x=5$], part[$x=6$]), columns: 1)[]
  #answer[$x=4$]
  #answer(ref: 5)[$x=7$]
  #answer[$x=8$]
]
#solutions[
  #solution(parts: (part(parts: (task[$x+1=3$], task(ref: "iii")[$x=2$], task[Check: $2+1=3$.]))[],))[]
  #solution(ref: 5)[$5x=35 => x=7$]
  #solution[$6x=48 => x=8$]
]
