#include "QualityConstraints_2.h"
#include "PermanentChoiceWithReset.ox"
#include "PermanentChoice_1.ox"

QualityConstraints_2::Replicate(){

decl KW, PD, PS;

Initialize(1.0,Reachable, FALSE, 0);			//For experiment
//SetClock(UncertainLongevity,TMax,0.0);
SetClock(NormalAging,TMax);
SetDelta(0.95);

/**Actions**/
	Actions(
		schoice = new ActionVariable("schoice", MSchooltype), //school choice;
		attend = new ActionVariable("attend", MAttendlabel), //attend school
		work = new ActionVariable("work", MWorklabel),
		savings = new ActionVariable("savings", MaxAssets),
	 	GrowUp = new ActionVariable("GrowUp", MPhaselabel)); //,

	work.actual = <0.0,0.5,1.0>;

/**State Variables:**/

//ENDOGENOUS STATES:

	EndogenousStates(
		GROWNUp = new PermanentChoice("GROWNUp", GrowUp),		
		Credits=  new Forget(new RandomUpDown("Credits", MaxCredits, QualityConstraints_2::Cr_Transit),GROWNUp,Forgotten),
		SchoolType = new Forget(new PermanentChoice("SchoolType", schoice)
					,GROWNUp,Forgotten),
		asset = new Asset("asset", MaxAssets, r, QualityConstraints_2::Savings), 
 		HC = new RandomUpDown("HC", MaxHC, QualityConstraints_2::HC_trans)
					);
	CreateSpaces();
	decl Emax = new ValueIteration();
	Emax -> Solve();
	PD = new PanelPrediction(0);
	PD -> Predict(TMax);
	PD -> Histogram(HC,TRUE,TRUE);
	PD -> Histogram(GrowUp,TRUE,TRUE);
	PD -> Histogram(Credits,TRUE,TRUE);
	PD -> Histogram(attend,TRUE,TRUE);	
//	PD -> Histogram(GROWNUp,TRUE,TRUE);
	delete PD;
}

/**CONSTRAINTS ON CHOICE:**/
QualityConstraints_2::FeasibleActions(const Alpha) {
	
	decl Age = curt + Age0, A;

	if (Age == Age0)
		return ! ( Alpha[][work.pos] + Alpha[][GrowUp.pos] +
				(Alpha[][schoice.pos].==Forgotten) );

	A = !( CV(GROWNUp) + Alpha[][schoice.pos] )            //After t=0, no choice
		+ CV(GROWNUp).*(Alpha[][schoice.pos].==Forgotten|| !Alpha[][attend.pos]); //After GROWNUp, no choice, but forgotten state

	if (curt >= MaxTAtt) 
			A .*= (Alpha[][GrowUp.pos]);  	/*Must grow up at certain age*/
	 else 
		 	A .*= !(Alpha[][GrowUp.pos]); 

//	if (curt >= TMax-2) A.*= (Alpha[][work.pos].==FullWork); //work full-time only
	
	return A;
	}

QualityConstraints_2::Reachable() {
	if ( (curt > MaxTAtt || CV(GROWNUp) ) && ( CV(SchoolType)!=Forgotten || CV(Credits)!=Forgotten ) ) return 0; 
	return new QualityConstraints_2();
	}

QualityConstraints_2::HC_trans(FeasA) {
     decl HC_up, HC_nc, HC_down;

//     Now RandomUpDown always takes 3 prob.
    HC_up = beta_0 + beta_1*(FeasA[][work.pos].==0) + beta_2*(FeasA[][work.pos].==1);
    HC_nc = beta_0 + beta_1*(FeasA[][work.pos].==0) + beta_2*(FeasA[][work.pos].==1) + beta_3*(FeasA[][work.pos].==2);
    HC_down = 1 - HC_up - HC_nc;
	if (any(HC_down~HC_nc~HC_up .< 0)) oxrunerror("HC probs. invalid");
     return HC_down~HC_nc~HC_up;
}



/**Transition of Credits**/
QualityConstraints_2::Cr_Transit(FeasA){
	decl prob_fail, prob_pass, prob_down;

	decl Age = curt + Age0;
	
  	if(!CV(GROWNUp)){
		decl ivals_work = FeasA[][work.pos], ivals_attend = FeasA[][attend.pos]; 
	    prob_pass = ivals_attend .? (theta_0 + theta_1*CV(Abil) + theta_5*(ivals_work.==0) + theta_6*(ivals_work.==.5) + theta_7*(ivals_work.==1)) .: 0;
		 }
	else{
		prob_pass = 0;
	}
	prob_down = 0;
	prob_fail = 1 - prob_pass;

	return prob_down ~ prob_fail ~ prob_pass;
}

 
QualityConstraints_2::Savings(FeasA){
	//println
	return savings.actual[FeasA[][savings.pos]]';
	}
 

QualityConstraints_2::Utility() {

	if (curt==TMax-1 || curt==0) return zeros(rows(A[Aind]),1);

//	wage = ((omega_1) + (omega_2)*CV(HC))*52 .*(work.actual[aa(work)]');
	wage = ((omega_1) + (omega_2))*52 .*(work.actual[aa(work)]');
 
	decl cons =	wage; // - savings.actual[aa(savings)]'; /*Consumption*/

	/*Total one period utility*/
	decl util = cons .<= 0.0 .? -.Inf .:  (cons.^(1-rho))/(1-rho) + aa(work)*gamma_22;

	return util;
	}
	