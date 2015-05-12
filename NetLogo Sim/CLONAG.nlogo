;------------------------------------------------------------------------------
;                   Copyright 2014 Andrew Wright
; This code was written under the supervision of John R. Page at the 
; University of New South Wales submited in partial requirement for the degree of Bacholer of Engineering (Aerospace)
;
;   Licensed under the Apache License, Version 2.0 (the "License");
;   you may not use this file except in compliance with the License.
;   You may obtain a copy of the License at
;
;       http://www.apache.org/licenses/LICENSE-2.0
;
;   Unless required by applicable law or agreed to in writing, software
;   distributed under the License is distributed on an "AS IS" BASIS,
;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;   See the License for the specific language governing permissions and
;   limitations under the License.
;------------------------------------------------------------------------------

__includes ["VariableDeclarations.nls" "Clonag.nls"]


to initGlobals
  ;;SETUP WORLD:: 
  ;initialise Globals
  ;colours
  set tickLength 0.1
  set backgroundColor blue
  set victimColor green
  set searcherColor orange
  set foundColor yellow
  set buildingColor white
  
  set Speed 0.5
  set smoothingFactor 1
  set visionAngle 30
  set-patch-size 8
  set RescueTime (50 / tickLength)
  set totalGATicks (500 / tickLength)
  
  ;;PATCHES
  ;patchVariable
  set VisitTimerMax decayRate / tickLength
  
  ;;REPORTERS
  ;Reporter Values, using Dummy Values
  set DONORMAL 1374
  set RIGHTTURN 2349
  set LEFTTURN 9584  
  
  ;;SEARCHERS
  set noSearchers population
  set searcherSize 1
  set searcherShape "airplane"
  
  ;;VICTIMS
  set victimSize 2
  set victimShape "person"
  set victimsFound 0
  
  ;BitSizes
  set tVisionBitLength 4
  set tCollisionDistanceBitLength 3
  set tMinimumSeparationBitLength 3
  set tMaxAlignTurnBitLength 4
  set tMaxCohereTurnBitLength 4
  set tMaxSeparateTurnBitLength 5
  set tMoveDistanceBitLength 3
  set tTrackingRangeBitLength 4
  set tDefaultTurnBitLength 1
  
  ;ImportWorldValues (RandomWorldGene)
end

to ImportWorldValues [WorldGene]
  set worldSizex item 0 WorldGene
  set worldSizey item 1 WorldGene
  set noVictims item 2 WorldGene
  set detectionChance item 3 WorldGene
  set victimDist item 4 WorldGene
  set currentStrength item 5 WorldGene
  set OceanTemperature item 6 WorldGene
end

to-report RandomWorldGene
  report (list (random 110 + 40)
    (random 110 + 40)
    (random 20 + 5)
    (random 90 + 10)
    (random 15 + 10)
    ((random 5 + 1) / 100)
    (random 20 + 10))
end

to initWorld
  resize-world (- worldSizex / 2)  (worldSizex / 2) (- worldSizey / 2) (worldSizex / 2)
  ;initialise world
  ask patches [set pcolor backgroundColor]
  build-rubble
  ;Generate Victim Patches
  let counteri 0
  let xrand random-pxcor
  let yrand random-pycor
  while [counteri < noVictims] [
    let xy coords (xrand) (yrand) (victimDist)
    if [pcolor] of patch item 0 xy item 1 xy = backgroundColor [
      set counteri (counteri + 1)
      create-victims 1 [
        setxy item 0 xy item 1 xy
        set color victimColor
        set shape victimShape
        set size victimSize
      ]
    ]
  ]
  
  ;victimVariables
  ask victims [
    set vDriftTurn (random-normal 8 1) * tickLength
    set vDriftMove (random-normal currentStrength 0.01) * tickLength
    set vCollisionRange 3
    set vSurvivalTime survivalTime
    ifelse random 2 = 0 [set tDefaultTurn LEFTTURN][set tDefaultTurn RIGHTTURN]
  ]
  
  ;Create Searcher Turtles
  ;set searcher variables
  set xrand random-xcor
  set yrand  random-ycor
  create-searchers  noSearchers [
    let xy coords (xrand) (yrand) (3)
    setxy item 0 xy item 1 xy
    set tToDie 0
    set tTurnLedger 0  
    set color searcherColor
    set shape searcherShape
    set size searcherSize
    set tSearching TRUE
    set tTrackPoints 0
  ]
end

to-report survivalTime
  ;report (random-normal ((0.02 * 60 * 60) * exp(0.16 * OceanTemperature)) (0.32 * (0.02 * 60 * 60) * exp(0.16 * OceanTemperature))) / tickLength / 10
  report ((0.03 * 60 * 60) * exp(0.16 * OceanTemperature)) / tickLength / 10
end

to-report coords [xrand yrand spaceing]
  let x random-normal xrand spaceing
  let y random-normal yrand spaceing
  while [x < min-pxcor or x > max-pxcor] [
    set x random-normal xrand spaceing
  ]
  while [y < min-pycor or y > max-pycor] [
    set y random-normal yrand spaceing
  ]
  report (list x y)
end

to reset
  ;;SETUP SIMULATION;;
  ;reset the state, time and view
  clear-ticks
  cp
  ct
  cd
  reset-perspective
end

to Setup
  clear-all
  reset
  initGlobals
  initWorld
  
  ;writeDataToFile (GenerateGeneticCode (population) (Hetro)) ("geneInfo.txt")
  
  
  let inputCode GenerateGeneticCode (population) (Hetro)
  
  if expt = "RANDOMHOMO"[
    set inputCode GenerateGeneticCode (population) (false)
    assignGenes(inputCode)]
  if expt = "RANDOMHETRO"[
    set inputCode GenerateGeneticCode (population) (true)
    assignGenes(inputCode)]
  if expt = "CRAFTED" [assignGenes (readDataFromFile ("Genes1Test"))]
  if expt = "HOMO1" [assignGenes (readDataFromFile ("Genes1Homo1"))]
  if expt = "HOMO2" [assignGenes (readDataFromFile ("Genes1Homo2"))]
  reset-ticks
end

to assignGenes [GeneticCode]
  ask searchers [
    set tGeneticCode item (([who] of self - (min [who] of searchers))) GeneticCode
    set tNewGeneticCode tGeneticCode 
    extractDNA (tGeneticCode)
  ]
end

to track
  ;check if the target is still in tracking range
  ifelse tTracking != nobody and distance tTracking < tTrackingRange [
    ;turn to attempt to track the target
    turn-towards (towards tTracking) (tMaxAlignTurn)
    set tTrackPoints (tTrackPoints + 1)
    
    ;check if any have tracked long ehough to rescue a victim
    ifelse tTrackCounter < 1 [
      resetTracking
      if tTracking != nobody [
        set victimsFound (victimsFound + 1 * [vSurvivalTime] of tTracking) 
        ask tTracking [die] 
        set tTrackPoints (tTrackPoints + 100)]
      set tTracking nobody
    ]
    ;otherwise decrement the tracking timer
    [set tTrackCounter (tTrackCounter - 1)] 
    
    
  ][
  resetTracking
  flock
  ]
end

to writeDataToFile [inputData file]
  file-open file
  file-write inputData
  file-close
end

to-report readDataFromFile [file]
  file-open file
  let outputData file-read
  file-close
  report outputData
end

to searcherBehave
  ;check between the turtle and the turtles maximum collision detectance range
  ;if there is nothing recommend continue as normal, otherwise recommend respond to the closest obstacle
  let range 0
  let action (doPath (range))
  let maxCheck 0
  ifelse (tSearching = TRUE) [set maxCheck tCollisionDistance][set maxCheck 1]
  
  while [range < maxCheck and action = DONORMAL] [
    set range (range + 0.5)
    set action doPath (range)
  ]
  
  ;based on the recommended action, respond accordingly
  ifelse (action = DONORMAL) [
    ifelse tSearching = TRUE [flock][track] 
    ;if (tMoveDistance < ((Speed) * tickLength)) [set tMoveDistance (tMoveDistance + (0.1 * Speed * tickLength * tickLength))]
  ] [
  ifelse (action = RIGHTTURN) [
    right tMaxSeparateTurn
    set tTurnLedger (tTurnLedger + 1) 
    ;if (tMoveDistance > 0) [set tMoveDistance (tMoveDistance - (0.1 * Speed * tickLength * tickLength))]
  ] [
  ifelse (action = LEFTTURN) [
    left tMaxSeparateTurn
    set tTurnLedger (tTurnLedger - 1)  
    ;if (tMoveDistance > 0) [set tMoveDistance (tMoveDistance - (0.1 * Speed * tickLength * tickLength))]
  ]
  [show "ERROR" show action stop]]]
end

to-report victimSighted [checkRange]
  ;initalise temp variables
  let reportValue nobody
  
  ;check what is ahead of the turtles path
  let target-patch1 patch-ahead checkRange
  if target-patch1 != nobody and count victims-on target-patch1 > 0 [
    if random 100 < DetectionChance [set reportValue one-of victims-on target-patch1]
  ]
  let target-patch2 patch-right-and-ahead visionAngle checkRange
  if target-patch2 != nobody and count victims-on target-patch2 > 0 [
    if random 100 < DetectionChance [set reportValue one-of victims-on target-patch2]
  ]
  let target-patch3 patch-left-and-ahead visionAngle checkRange
  if target-patch3 != nobody and count victims-on target-patch3 > 0 [
    if random 100 < DetectionChance [set reportValue one-of victims-on target-patch3]
  ]
  
  ;report the best course of action
  report reportValue
end

to resetTracking
  set tSearching TRUE
  set color searcherColor
end

to victimBehave
  ;check between the turtle and the turtles maximum collision detectance range
  ;if there is nothing recommend continue as normal, otherwise recommend respond to the closest obstacle
  let range 0
  let action (doPath (range))
  
  if vSurvivalTime <= 0 [die]
  set vSurvivalTime (vSurvivalTime - 1)
  
  while [range < vCollisionRange and action = DONORMAL] [
    set range (range + 1)
    set action doPath (range)
  ]
  
  ;based on the recommended action, respond accordingly
  ifelse (action = DONORMAL) [
    ;basic random drift for victims
    ifelse (random 2 = 0)[left vDriftTurn][right vDriftTurn]
    fd (vDriftMove)
  ] [
  ifelse (action = RIGHTTURN) [
    right vDriftTurn
  ] [
  ifelse (action = LEFTTURN) [
    left vDriftTurn 
  ]
  [show "ERROR" show action stop]]]
end

to-report GenerateGeneticCode [populationGGC isHetroGGC]
  let TotalGene []
  let counter 0
  let tempGene []
  
  ifelse isHetroGGC = TRUE [ ;Genereate a seperate ranndom gene for every member of the population
    while [counter < populationGGC] [
      set counter (counter + 1)
      set tempGene randomGeneCode
      set TotalGene lput tempGene TotalGene
    ]
  ]
  [;genereate a random gene then copy it exactly to every member of the population
    set tempGene randomGeneCode
    while [counter < populationGGC] [
      set counter (counter + 1)
      set TotalGene lput tempGene TotalGene
    ]
  ]
  
  report TotalGene
end

to-report randomGeneCode
  report (list
    (n-values tVisionBitLength [random 2]);tVision (0-10)
    (n-values tCollisionDistanceBitLength [random 2]);tCollisionDistance (0-10)
    (n-values tMinimumSeparationBitLength [random 2]);tMinimumSeperation (0-20)
    (n-values tMaxAlignTurnBitLength [random 2]);MaxAlignTurn (0-30)
    (n-values tMaxCohereTurnBitLength [random 2]);tMaxCohereTurn (0-30)
    (n-values tMaxSeparateTurnBitLength [random 2]);tMaxSeparateTurn (0-30)
    (n-values tMoveDistanceBitLength [random 2]);tMoveDistance (0-3)
    (n-values tTrackingRangeBitLength [random 2]);tTrackingRange (0-3)
    (n-values tDefaultTurnBitLength [random 2]);tDefaultTurn
    )
end

to-report evolveGA
  let TotalGene []
  let counter 0
  let bestIndex position last sort fitnessList fitnessList
  while [counter < populationGA] [
    let tempGene item bestIndex gaListOld
    set tempGene mutateGA (tempGene)
    set TotalGene lput tempGene TotalGene
    set counter (counter + 1)
  ]
  report TotalGene
end

to-report calcFitnessGA
  let timeFitness 1 - ((ticks - rescueTime - 1) / (totalGATicks - rescueTime)) ;percentage of total time needed
  let foundFitness (victimsFound / (noVictims * survivalTime)) ;percentage of total victims found
  report foundFitness
end

;;THIS SECTION OF CODE IS BASED ON 
;Stonedahl, F. and Wilensky, U. (2008). NetLogo Simple Genetic Algorithm model. 
;http://ccl.northwestern.edu/netlogo/models/SimpleGeneticAlgorithm. 
;Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
to-report create-next-generation
  let TotalGene []
  let crossover-count  (floor (populationGA * crossover-rate / 100 / 2))
  let t1Size 4
  let t2Size (10)
  repeat crossover-count [
    ;select the parents, p1 and p2
    let p1 position last sort (n-of t1Size fitnessList) fitnessList
    let p2 position last sort (n-of t1Size fitnessList) fitnessList
    
    let child-bits crossover (mutateGA (item p1 gaListOld)) (mutateGA (item p2 gaListOld))
    ; create the two children, with their new genetic material
    set TotalGene lput item 0 child-bits TotalGene
    set TotalGene lput item 1 child-bits TotalGene
  ]
  
  repeat (populationGA - crossover-count * 2)
  [
    let p3 position last sort (n-of t2Size fitnessList) fitnessList
    set TotalGene lput mutateGA (item p3 gaListOld) TotalGene
  ]
  report TotalGene
end

to-report crossover [bits1 bits2]
  let split-point 1 + random (length bits1 - 1)
  report list (sentence (sublist bits1 0 split-point)
                        (sublist bits2 split-point length bits2))
              (sentence (sublist bits2 0 split-point)
                        (sublist bits1 split-point length bits1))
end

to setupGA
  clear-all
  ;First Run
  set generationNo 0
  reset
  initGlobals
  ImportWorldValues (RandomWorldGene)
  initWorld
  reset-ticks
  set fitnessList []
  set gaListOld GenerateGeneticCode (populationGA) (TRUE)
end

to setupCLONAG
  clear-all
  ;First Run
  reset
  initGlobals
  ImportWorldValues (RandomWorldGene)
  initWorld
  reset-ticks
  set fitnessList []
  set Ab GenerateGeneticCode (populationGA) (TRUE)
  set M 10
  set Ag n-values M [RandomWorldGene]
  set Abm n-values M [randomGeneCode] ;change the length of this, fill with zeros?
  set fm n-values M [0] ;change the length of this, fill with zeros?
end

to goCLONAG
  if generationNo >= maxGenerations [stop]
  ;;
  let j 0
  let n 5
  let Beta 1
  
  while [j < M] [
    ;;
    let Agj item j Ag ;1
    ;show "testing"
    let fj affinity (Ab) (Agj) ;2
    let Abjn select (n) (Ab) (fj) ;3
    let fjn select (n) (fj) (fj) ;3B the shorter ordered fitness list, corresponding to the elements of Abjn
    let Cj clone (Abjn) (Beta) (fjn) ;4
    let fjCn clone (fjn) (Beta) (fjn) ;4B the cloned fitness list, corresponding to the elements of Cj
    let Cjstar hypermut (Cj) (fjCn) ;5
    ;show "testing clones"
    let fjstar affinity (Cjstar) (Agj);6
    let Abstar first select (1) (Cjstar) (fjstar);7
    let fAbStar item (position Abstar Cjstar) fjstar ;7B the shorter fitness list corresponding to that of Abstar
    if fAbStar >= (item j fm) [set Abm replace-item j Abm Abstar set fm replace-item j fm fAbStar]
    set Ab rebuild (Ab) (Abm) ;8
    
    ;increment the counter
    ;show j
    set j (j + 1)
  ]
  ;;
  set generationNo (generationNo + 1) 
end

to goGA
  if generationNo > maxGenerations [stop]
  ;Run with the new generation
  let counter 0
  set fitnessList []
  while [counter < populationGA] [
    let i 0
    let fitnessTemp 0
    while [i < noReps] [
      set fitnessTemp (fitnessTemp + modelRun (counter))
      set i (i + 1)
    ]
    set fitnessList lput (fitnessTemp / noReps) fitnessList
    set counter (counter + 1)
  ]
  plotFitness
  set generationNo (generationNo + 1)
  ;Create the Next generation
  ;set gaListOld evolveGA
  set gaListOld create-next-generation
  if last sort fitnessList > 0.80 and generationNo > 2 [stop]
end

to plotFitness
  set-current-plot "FitnessVSGen"
  set-current-plot-pen "pen-0"
  plot-pen-down
  plotxy generationNo ((sum fitnessList) / populationGA) 
  plot-pen-up
  set-current-plot-pen "pen-1"
  plot-pen-down
  plotxy generationNo (last sort fitnessList) 
  plot-pen-up
end

to-report modelRun [index]
  reset
  initGlobals
  initWorld
  reset-ticks
  ask searchers [
    set tGeneticCode item index gaListOld
    set tNewGeneticCode tGeneticCode
    extractDNA (tGeneticCode)
  ]
  loop [
    if not any? victims [report calcFitnessGA]
    if (ticks) >= (totalGATicks) [report calcFitnessGA]
    go
  ]
end

to-report modelRunCLONAG [inputGene Agj]
  reset
  initGlobals
  ImportWorldValues (Agj)
  initWorld
  reset-ticks
  ask searchers [
    set tGeneticCode inputGene
    set tNewGeneticCode tGeneticCode
    extractDNA (tGeneticCode)
  ]
  loop [
    if not any? victims [report calcFitnessGA]
    if (ticks) >= (totalGATicks) [report calcFitnessGA]
    go
  ]
end

to go
  ;ask the searchers to consider their situation, choose appropriate action
  ask searchers [
    searcherBehave
  ]
  ;run the basic victim drift behaviour
  ask victims [
    victimBehave
  ]
  
  ;Move searchers, using basic smoothing
  repeat smoothingFactor [ ask searchers [ fd (1 / smoothingFactor) * tMoveDistance ] display ]
  
  ;award points to searchers based on how recently a patch has been visited
  ask searchers with [tSearching = TRUE] [if (pcolor != buildingColor) [set tPatchCount (tPatchCount + (1 / (pVisitTimer + 1))) ask patch-here [set pVisitTimer VisitTimerMax]]]
  ;ask patches with [pcolor != buildingColor] [set pcolor scale-color blue pVisitTimer VisitTimerMax red]
  ask patches [if pVisitTimer > 0 [set pVisitTimer (pVisitTimer - 1)]]
  
  ;code to track tyrtle deaths, not usually required  
  ask searchers [
    if (pcolor = buildingColor) [set tToDie (tToDie + 1)]
    if (turtleColision = TRUE and count other turtles-on patch-here > 0) [set tToDie (tToDie + 1)]
  ]
    
  ;Evolve the Population
  if (doEvolveCS = TRUE) and (ticks > 400) and (ticks mod divisionRate = 0) [evolveCS]    
  tick 
end

to evolveCS
  ;if (debug = TRUE) [show "evolve"]
  ask searchers [calcFitnessCS] ;calculate fitness
  let agentsByFitness sort-on [tFitness] searchers ;sort the agents by fitness
  ask last agentsByFitness [
    set tNewGeneticCode [tNewGeneticCode] of first agentsByFitness
    set tToDie [tToDie] of first agentsByFitness
    mutateCS
    extractDNA (tNewGeneticCode)
  ]
end

to calcFitnessCS
  ;set tFitness ((tToDie * abs(tTurnLedger)) / (tPatchCount + 1))
  set tFitness (1 / ((tPatchCount + 1) * (tTrackPoints + 1)))
  ;set tFitness (tToDie)
end

to-report mutateGA [inputGene]
  let pGeneFlip 9
  let i 0
  let imax length inputGene - 1
  while [i < imax] [
    let j 0
    let jmax length item i inputGene - 1
    while [j < jmax] [
      if random pGeneFlip = 0 [ 
        let oldGene item i inputGene
        ifelse item j oldGene = 0 [set oldGene replace-item j oldGene 1][set OldGene replace-item j oldGene 0]
        set inputGene replace-item i inputGene oldGene
      ]
      set j (j + 1)
    ]
    set i (i + 1)
  ]
  report inputGene 
end

to mutateCS
  ;this looks like the gene coding could be removed and replaced with a rand = 0 statment see mutateGA
  let pGeneFlip MutationRate
  let i 0
  let imax length tNewGeneticCode - 1
  while [i < imax] [
    let j 0
    let jmax length item i tNewGeneticCode - 1
    while [j < jmax] [
      if random pGeneFlip = 0 [ 
        let oldGene item i tNewGeneticCode
        ifelse item j oldGene = 0 [set oldGene replace-item j oldGene 1][set OldGene replace-item j oldGene 0]
        set tNewGeneticCode replace-item i tNewGeneticCode oldGene
      ]
      set j (j + 1)
    ]
    set i (i + 1)
  ] 
end

to build-rubble
  let xrand round random-normal 0 6
  let yrand round random-normal 0 4
  ask patches [
    ifelse density = 0 [set odds 10000000][set odds ((1 / (density / 2)) * 100)]

    if (random odds = 0) [ 
      set pcolor buildingColor 
    ]
  ]
end


to-report doPath [checkRange]
  ;initalise temp variables
  let blocked FALSE
  let lblocked FALSE
  let rblocked FALSE
  let reportValue 9985
  
  ;check what is ahead of the turtles path
  let target-patch1 patch-ahead checkRange
  if target-patch1 = nobody or [pcolor] of target-patch1 = buildingColor or (count other searchers-on target-patch1 > 0 and turtleColision = TRUE) or count [neighbors] of target-patch1 < 8 [
    set blocked TRUE
  ]
  let target-patch2 patch-right-and-ahead visionAngle checkRange
  if target-patch2 = nobody or [pcolor] of target-patch2 = buildingColor or (count other searchers-on target-patch2 > 0 and turtleColision = TRUE) or count [neighbors] of target-patch1 < 8 [
    set rblocked TRUE
  ]
  let target-patch3 patch-left-and-ahead visionAngle checkRange
  if target-patch3 = nobody or [pcolor] of target-patch3 = buildingColor or (count other searchers-on target-patch3 > 0 and turtleColision = TRUE) or count [neighbors] of target-patch1 < 8 [
    set lblocked TRUE
  ]
  
  ;decide on the best course of action
  ifelse ((blocked = TRUE) and (rblocked = TRUE) and (lblocked = TRUE)) [set reportValue tDefaultTurn] [
  ifelse ((blocked = TRUE) and (rblocked = FALSE) and (lblocked = FALSE)) [set reportValue tDefaultTurn] [
  ifelse ((blocked = FALSE) and (rblocked = TRUE) and (lblocked = TRUE)) [set reportValue tDefaultTurn] [
  ifelse ((blocked = TRUE) and (rblocked = TRUE) and (lblocked = FALSE)) [set reportValue LEFTTURN] [
  ifelse ((blocked = TRUE) and (rblocked = FALSE) and (lblocked = TRUE)) [set reportValue RIGHTTURN] [
  ifelse ((blocked = FALSE) and (rblocked = TRUE) and (lblocked = FALSE)) [set reportValue LEFTTURN] [
  ifelse ((blocked = FALSE) and (rblocked = FALSE) and (lblocked = TRUE)) [set reportValue RIGHTTURN] [
  ifelse ((blocked = FALSE) and (rblocked = FALSE) and (lblocked = FALSE)) [set reportValue DONORMAL][show "ERROR" show reportValue stop] ]]]]]]]
  ;report the best course of action
  report reportValue
end


to extractDNA [GeneticCode]
  let decCode grayToDec (GeneticCode)
  ;show binaryCode
  set tVision item 0 decCode
  set tCollisionDistance item 1 decCode
  set tMinimumSeparation item 2 decCode + 1
  set tMaxAlignTurn (item 3 decCode * tickLength)
  set tMaxCohereTurn (item 4 decCode * tickLength)
  set tMaxSeparateTurn (item 5 decCode * tickLength)
  set tMoveDistance (item 6 decCode * tickLength * 0.1 + 1 * tickLength)
  set tTrackingRange (item 7 decCode)
  ifelse item 8 decCode = 0 [set tDefaultTurn LEFTTURN][set tDefaultTurn RIGHTTURN]
  ;show decCode
end

to-report grayToDec [grayCode]
  let decCode []
  let i 0
  while [i < length grayCode] [
    let subBinaryCode []
    let decTotal 0
    set subBinaryCode (lput (first (item i grayCode)) subBinaryCode)
    set decTotal (decTotal + (2 ^ (length (item i grayCode) - 1) * first subBinaryCode))
    
    let j 1
    while [j < length (item i grayCode)] [
      let Gcurrent item j (item i grayCode)
      let Bprevious item (j - 1) subBinaryCode
      ifelse (Gcurrent + Bprevious) = 2[set subBinaryCode lput 0 subBinaryCode][set subBinaryCode lput (Gcurrent + Bprevious) subBinaryCode]
      set decTotal (decTotal + (2 ^ (length (item i grayCode) - j - 1) * item j subBinaryCode))
      set j (j + 1)  
    ]
    set decCode lput decTotal decCode
    set i (i + 1)
  ]
  report decCode
end

;-------- The following portion of Code is taken from: --------
;Wilensky, U. (1998). NetLogo Flocking model. 
;http://ccl.northwestern.edu/netlogo/models/Flocking. 
;Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
;It and any code in conjunction must be licensed under Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License
;-------- -------------------------------------------- --------
to flock  ;; turtle procedure
  find-flockmates
  if any? flockmates
    [ find-nearest-neighbor
      ifelse distance nearest-neighbor < tMinimumSeparation
        [ separate ]
        [ align
          cohere ] ]
    
  let range 1
  let sighted victimSighted (range)
  while [range < 3 and sighted = nobody] [
    set range (range + 1)
    set sighted victimSighted (range)
  ]
  if sighted != nobody [
    set tSearching FALSE
    face sighted
    set color foundColor
    set tTracking sighted
    set tTrackCounter RescueTime
  ]
end

to find-flockmates  ;; turtle procedure
  set flockmates other searchers in-radius tVision
end

to find-nearest-neighbor ;; turtle procedure
  set nearest-neighbor min-one-of flockmates [distance myself]
end

;;; SEPARATE

to separate  ;; turtle procedure
  turn-away ([heading] of nearest-neighbor) tMaxSeparateTurn
end

;;; ALIGN

to align  ;; turtle procedure
  turn-towards average-flockmate-heading tMaxAlignTurn
end

to-report average-flockmate-heading  ;; turtle procedure
  ;; We can't just average the heading variables here.
  ;; For example, the average of 1 and 359 should be 0,
  ;; not 180.  So we have to use trigonometry.
  let x-component sum [dx] of flockmates
  let y-component sum [dy] of flockmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end


;;; COHERE

to cohere  ;; turtle procedure
  turn-towards average-heading-towards-flockmates tMaxCohereTurn
end

to-report average-heading-towards-flockmates  ;; turtle procedure
  ;; "towards myself" gives us the heading from the other turtle
  ;; to me, but we want the heading from me to the other turtle,
  ;; so we add 180
  let x-component mean [sin (towards myself + 180)] of flockmates
  let y-component mean [cos (towards myself + 180)] of flockmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

;;; HELPER PROCEDURES

to turn-towards [new-heading max-turn]  ;; turtle procedure
  turn-at-most (subtract-headings new-heading heading) max-turn
end

to turn-away [new-heading max-turn]  ;; turtle procedure
  turn-at-most (subtract-headings heading new-heading) max-turn
end

;; turn right by "turn" degrees (or left if "turn" is negative),
;; but never turn more than "max-turn" degrees
to turn-at-most [turn max-turn]  ;; turtle procedure
  ifelse abs turn > max-turn
    [ ifelse turn > 0
        [ rt max-turn ]
        [ lt max-turn ] ]
    [ rt turn ]
end
;-------- The above portion of Code is taken from: --------
;Wilensky, U. (1998). NetLogo Flocking model. 
;http://ccl.northwestern.edu/netlogo/models/Flocking. 
;Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
;It and any code in conjunction must be licensed under Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License
;-------- ---------------------------------------- --------
@#$#@#$#@
GRAPHICS-WINDOW
15
10
674
585
40
-1
8.0
1
10
1
1
1
0
0
0
1
-40
40
-27
40
1
1
1
ticks
30.0

BUTTON
1499
17
1563
50
NIL
Setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1500
53
1563
86
NIL
Go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1499
265
1671
298
population
population
0
200
20
1
1
NIL
HORIZONTAL

SLIDER
1499
162
1671
195
Density
Density
0
100
0
0.1
1
%
HORIZONTAL

MONITOR
1730
249
1811
294
Alive Turtles
count searchers
0
1
11

SLIDER
1887
95
2059
128
divisionRate
divisionRate
100
3000
100
1
1
NIL
HORIZONTAL

CHOOSER
1517
303
1655
348
TurtleColision
TurtleColision
true false
0

MONITOR
1822
249
1907
294
NIL
count victims
17
1
11

SLIDER
1499
93
1671
126
worldSizex
worldSizex
0
150
81
1
1
NIL
HORIZONTAL

SLIDER
1499
127
1671
160
worldSizey
worldSizey
0
150
54
1
1
NIL
HORIZONTAL

SLIDER
1888
129
2060
162
decayRate
decayRate
0
100
50
1
1
NIL
HORIZONTAL

SLIDER
1499
230
1671
263
noVictims
noVictims
0
100
10
1
1
NIL
HORIZONTAL

SLIDER
1499
197
1671
230
DetectionChance
DetectionChance
0
100
71
1
1
NIL
HORIZONTAL

BUTTON
1567
53
1650
86
Go GA
goGA
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1693
165
1865
198
populationGA
populationGA
0
50
15
1
1
NIL
HORIZONTAL

CHOOSER
1517
350
1655
395
Hetro
Hetro
true false
1

CHOOSER
1907
168
2045
213
doEvolveCS
doEvolveCS
true false
1

PLOT
1732
338
1989
543
FitnessVSGen
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"pen-0" 1.0 0 -2674135 true "" ""
"pen-1" 1.0 0 -13345367 true "" ""

SLIDER
1693
199
1866
232
maxGenerations
maxGenerations
0
75
10
1
1
NIL
HORIZONTAL

BUTTON
1567
17
1650
50
Setup GA
setupGA
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1690
94
1862
127
noReps
noReps
1
10
3
1
1
NIL
HORIZONTAL

SLIDER
1690
129
1862
162
crossover-rate
crossover-rate
0
100
75
1
1
NIL
HORIZONTAL

CHOOSER
1520
398
1659
444
expt
expt
"RANDOMHOMO" "RANDOMHETRO" "CRAFTED" "HOMO1" "HOMO2"
4

SLIDER
1907
217
2080
251
MutationRate
MutationRate
1
50
30
0.5
1
NIL
HORIZONTAL

CHOOSER
1524
448
1663
494
RandomizeWorld
RandomizeWorld
true false
1

SLIDER
1500
500
1673
534
victimDist
victimDist
1
40
16
1
1
NIL
HORIZONTAL

SLIDER
1502
539
1675
573
currentStrength
currentStrength
0
10
0.01
0.01
1
NIL
HORIZONTAL

SLIDER
1490
577
1684
611
OceanTemperature
OceanTemperature
0
30
17
1
1
deg C
HORIZONTAL

BUTTON
1658
19
1768
53
NIL
setupCLONAG
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1658
55
1768
89
Go Clonag
goCLONAG
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="33" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <metric>mean [tVision] of searchers</metric>
    <metric>mean [tCollisionDistance] of searchers</metric>
    <metric>mean [tMinimumSeparation] of searchers</metric>
    <metric>mean [tMaxAlignTurn] of searchers</metric>
    <metric>mean [tMaxCohereTurn] of searchers</metric>
    <metric>mean [tMaxSeparateTurn] of searchers</metric>
    <metric>mean [tMoveDistance] of searchers</metric>
    <metric>mean [tDefaultTurn] of searchers</metric>
    <metric>TurtleColision</metric>
    <enumeratedValueSet variable="population">
      <value value="50"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Density" first="0" step="0.5" last="75"/>
    <enumeratedValueSet variable="TurtleColision">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Moitor" repetitions="33" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>missionSuccess</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="DetectionChance">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="worldSizex">
      <value value="96"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decayRate">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="worldSizey">
      <value value="94"/>
    </enumeratedValueSet>
    <steppedValueSet variable="noVictims" first="1" step="1" last="30"/>
    <enumeratedValueSet variable="divisionRate">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Density">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TurtleColision">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="GAexperiment" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>goGA</go>
    <metric>last sort fitnessList</metric>
    <metric>item (position last sort fitnessList fitnessList) gaListOld</metric>
    <enumeratedValueSet variable="noVictims">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doEvolveCS">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="worldSizex">
      <value value="74"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxGenerations">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TurtleColision">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="divisionRate">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Density">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decayRate">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hetro">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="worldSizey">
      <value value="74"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="25"/>
    </enumeratedValueSet>
    <steppedValueSet variable="DetectionChance" first="10" step="10" last="100"/>
    <enumeratedValueSet variable="populationGA">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="controlGA" repetitions="1000" runMetricsEveryStep="false">
    <setup>setupGA</setup>
    <go>goGA</go>
    <metric>last sort fitnessList</metric>
    <metric>mean fitnessList</metric>
    <metric>item 0 grayToDec (item (position last sort fitnessList fitnessList) gaListOld)</metric>
    <metric>item 1 grayToDec (item (position last sort fitnessList fitnessList) gaListOld)</metric>
    <metric>item 2 grayToDec (item (position last sort fitnessList fitnessList) gaListOld)</metric>
    <metric>item 3 grayToDec (item (position last sort fitnessList fitnessList) gaListOld)</metric>
    <metric>item 4 grayToDec (item (position last sort fitnessList fitnessList) gaListOld)</metric>
    <metric>item 5 grayToDec (item (position last sort fitnessList fitnessList) gaListOld)</metric>
    <metric>item 6 grayToDec (item (position last sort fitnessList fitnessList) gaListOld)</metric>
    <metric>item 7 grayToDec (item (position last sort fitnessList fitnessList) gaListOld)</metric>
    <metric>item 8 grayToDec (item (position last sort fitnessList fitnessList) gaListOld)</metric>
    <metric>calcFitnessGA</metric>
    <metric>worldSizey * worldSizex</metric>
    <metric>noVictims</metric>
    <metric>detectionChance</metric>
    <metric>victimDist</metric>
    <metric>density</metric>
    <metric>OceanTemperature</metric>
    <metric>currentStrength</metric>
    <enumeratedValueSet variable="population">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TurtleColision">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="divisionRate">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="populationGA">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxGenerations">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decayRate">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hetro">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doEvolveCS">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="noVictims">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="noReps">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="crossover-rate">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomizeWorld">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ThesisRun12" repetitions="5000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>not any? victims or ticks &gt; 5000</exitCondition>
    <metric>calcFitnessGA</metric>
    <metric>worldSizey * worldSizex</metric>
    <metric>noVictims</metric>
    <metric>detectionChance</metric>
    <metric>victimDist</metric>
    <metric>density</metric>
    <metric>OceanTemperature</metric>
    <metric>currentStrength</metric>
    <enumeratedValueSet variable="Hetro">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doEvolveCS">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TurtleColision">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="crossover-rate">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decayRate">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxGenerations">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Density">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="noReps">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="populationGA">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="divisionRate">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expt">
      <value value="&quot;RANDOMHETRO&quot;"/>
      <value value="&quot;CRAFTED&quot;"/>
      <value value="&quot;HOMO1&quot;"/>
      <value value="&quot;HOMO2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomizeWorld">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="density">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MutationRate">
      <value value="30"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ThesisRun13" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>not any? victims or ticks &gt; 5000</exitCondition>
    <metric>calcFitnessGA</metric>
    <enumeratedValueSet variable="Hetro">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doEvolveCS">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DetectionChance">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TurtleColision">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="worldSizey">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="crossover-rate">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decayRate">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxGenerations">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Density">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="noReps">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="populationGA">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="divisionRate">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="worldSizex">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="noVictims">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expt">
      <value value="&quot;CRAFTED&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MutationRate">
      <value value="13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="divisionRate">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RandomizeWorld">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="OceanTemperature" first="0" step="1" last="30"/>
  </experiment>
  <experiment name="CLONAGrun" repetitions="1" runMetricsEveryStep="true">
    <setup>setupCLONAG</setup>
    <go>goCLONAG</go>
    <metric>Ab</metric>
    <metric>Ag</metric>
    <metric>Abm</metric>
    <metric>fm</metric>
    <metric>item 0 fm</metric>
    <metric>item 1 fm</metric>
    <metric>item 2 fm</metric>
    <metric>item 3 fm</metric>
    <metric>item 4 fm</metric>
    <metric>item 5 fm</metric>
    <metric>item 6 fm</metric>
    <metric>item 7 fm</metric>
    <metric>item 8 fm</metric>
    <metric>item 9 fm</metric>
    <enumeratedValueSet variable="Hetro">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doEvolveCS">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TurtleColision">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RandomizeWorld">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="crossover-rate">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decayRate">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxGenerations">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Density">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="noReps">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="populationGA">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="divisionRate">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@