/*******************************************************************************
Template estimand code for each different intercurrent event strategy
*******************************************************************************/

/*******************************************************************************
									NOTES
- Template uses ICE as a placeholder for a variable that marks whether a 
   participant has had the IE (1) or not (0)
  
- The "analysis" used will be a simple regression with a few common adjusting 
   variables
   
- The outcome is a placeholder called outcome 

*******************************************************************************/

					////////////////////////////////////////
						  //# Treatment policy #//
					////////////////////////////////////////
						
	// This includes all participants in the analysis, using the outcome data 
	// observed , regardless of the occurence of the IE
	
		regress outcome i.allocation c.age i.sex
	
	


					////////////////////////////////////////
						       //# Composite #//
					////////////////////////////////////////
						
	// Choose a value that those who have had the IE will have their outcome
	// changed to. Use this altered outcome in the analysis, using all 
	// participants
	
	// Here, we imagine the outcome is a change, therefore we set the outcome to
	// 0 if the participant has had the IE of interest
	
	// Generate the composite outcome
		gen comp_outcome = outcome
			replace comp_outcome = 0 if IE == 1
		
	// Run the analysis based on the composite outcome 
		regress comp_outcome i.allocation c.age i.sex
	
	


					////////////////////////////////////////
						   //# While on treatment #//
					////////////////////////////////////////
						
	// Change outcome to the last known outcome where there are multiple outcomes
	// taken before the primary outcome
	
	// For this example, outcomes are at 2 4 and 6 weeks (6-week primary) and
	// IE's are also measured at 2,4 and 6 weeks
	
	// Generate the While on treatment outcome 
		gen while_outcome = outcome_6weeks
	
		// Replace those who had the IE at 6-weeks with their 4-week outcome 
			replace while_outcome = outcome_4weeks if IE_6weeks == 1
		
		// Replace those who had the IE at 4-weeks with their 2-week outcome 
			replace while_outcome = outcome_2weeks if IE_4weeks == 1
		
		// Replace those who had the IE at 2-weeks with their baseline outcome 
			replace while_outcome = outcome_base if IE_2weeks == 1
		
	// Run the analysis using the while on treatment outcome
		regress while_outcome i.allocation c.age i.sex outcome_base
	
	


					////////////////////////////////////////
						      //# Hypothetical #//
					////////////////////////////////////////
						
	// If those who had the IE had not had the IE, what woud their outcome be,
	// based on a per protocol dataset
	
	// Need to flip the ICE (0=1 and 1=0, 0 now denotes having the IE and 1 
	//  denotes not having it)
		gen IE_flipped = IE
			recode IE_flipped (0=1) (1=0)
		
	// Define those in the per-protocol population
		// Allocation - 0 = control, 1 = Intervention
		// Per protocol should include (per_prot = 1) all those who have not had
		//  the IE (for simplicity, in actual trial more complex set of 
		//  exclusions)
		gen per_prot = IE_flipped 
	
	// Generate the weights for the regression (to upweight those who didn't
	//  have the ICE but are similar in specific characteristcs)
		logistic IE_flipped c.age i.sex
	
		// From this, predict weights
			predict prob_weight_hyp, pr
		
		// Generate the inverse weights
			gen weight = 1/prob_weight_hyp
		
	// Fit the model using the weight (per protocol analysis with weights)
		regress outcome i.allocation c.age i.sex if per_prot == 1 [pweight = weight]
	
	


					////////////////////////////////////////
						    //# Principal Stratum #//
					////////////////////////////////////////
						
	// Flip the IE  (0=1 and 1=0, 0 now denotes having the ICE and 1 denotes 
	//  not having it)
		gen IE_flipped = IE
			recode IE_flipped (0=1) (1=0)
		
	// Logistic model to predict weights of the intervention arm
		logistic IE_flipped c.age i.sex if allocation == 1
		
		// Predictions for the control arm participants
			predict prob_weight_hyp_cont if arm == 0, pr
		
	// Logistic model to predict weights of the control arm
		logistic IE_flipped c.age i.sex if allocation == 0
		
		// Predictions for the intervention arm participants
			predict prob_weight_hyp_int if allocation == 1, pr
			
	// Create a weights variable 
		gen weights = .
			replace weights = prob_weight_hyp_cont if allocation == 0
			replace weights = prob_weight_hyp_int  if allocation == 1
			
	// Run the analysis with the weights, and excluding those with the IE
		regress outcome i.allocation c.age i.sex if IE == 0 [pweight = weights]
	
