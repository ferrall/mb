#include "QualityConstraints_2.h"
#include "PermanentChoiceWithReset.ox"
#include "PermanentChoice_1.ox"

QualityConstraints_2::Replicate(){

decl KW, PD, PS;

Initialize(1.0,Reachable, TRUE, 0);
//SetClock(UncertainLongevity,TMax,0.0);
SetClock(NormalAging,TMax);
SetDelta(0.95);

/**Actions**/
	Actions(
		work = new ActionVariable("work", MWorklabel),
	//	attend = new ActionVariable("attend", MAttendlabel), //attend school
		schoice = new ActionVariable("schoice", MSchooltype), //school choice;
	 	GrowUp = new ActionVariable("GrowUp", MPhaselabel)); //,

	work.actual = <0.0,0.5,1.0>;

/**State Variables:**/

//ENDOGENOUS STATES:

	EndogenousStates(
// 		HC = new RandomUpDown("HC", MaxHC, QualityConstraints_2::HC_trans),
//		Credits= new RandomUpDown("Credits", MaxCredits, QualityConstraints_2::Cr_Transit),
		GROWNUp = new PermanentChoice("GROWNUp", GrowUp),
		SchoolType = new PermanentChoiceWithReset("SchoolType", schoice, GrowUp));
//		SchoolType = new PermanentChoice("SchoolType", schoice));
	
	CreateSpaces();
//	Volume = NOISY;
	decl Emax = new ValueIteration(0);
	Emax -> Solve(0,0);
	PD = new PanelPrediction(0);
	PD -> Predict(22);
	PD -> Histogram(GrowUp,TRUE,TRUE);
	PS = new PanelPrediction(0);
	PS -> Predict(22);
	PS -> Histogram(SchoolType,TRUE,TRUE);
	delete PD;
}

/**CONSTRAINTS ON CHOICE:**/
QualityConstraints_2::FeasibleActions(const Alpha) {
	
	decl Age = curt + Age0, A;

	//if (Age == Age0) println(Alpha~(!Alpha[][work.pos] .* !Alpha[][GrowUp.pos]));

	if (Age == Age0) return !Alpha[][work.pos] .* !Alpha[][GrowUp.pos];

	A = (Alpha[][schoice.pos].==0);

	if (curt >= MaxTAtt)  {
		A .*= (Alpha[][GrowUp.pos].==1);  	/*Must grow up at certain age*/
		}

	/*If already GROWNUP, must choose GrowUp every period*/
	if (CV(GROWNUp) == 1) {
		A .*= (Alpha[][GrowUp.pos].==1); 
		}
	if(curt >= TMax-2) A.*= (Alpha[][work.pos].==2); //work full-time only
	
	return A;
	}

QualityConstraints_2::Reachable() {

		if(curt > MaxTAtt && !GROWNUp.v) return 0;
		//PermanentChoiceWithReset will not work if below is commented out. Not sure why.
		if (SchoolType.v > 0 && curt > MaxTAtt) return 0; 
    	if (SchoolType.v > 0 && GROWNUp.v ==1) return 0; //forget school type one working age 

		return new QualityConstraints_2();
}
/*
QualityConstraints_2::HC_trans(FeasA) {
     decl HC_up, HC_nc, HC_down;

     if(curt<TMax-2){
         HC_up = beta_0 + beta_1*(FeasA[][work.pos].==0) + beta_2*(FeasA[][work.pos].==1);
         HC_nc = beta_0 + beta_1*(FeasA[][work.pos].==0) + beta_2*(FeasA[][work.pos].==1) + beta_3*(FeasA[][work.pos].==2);
		 }
     else {
         HC_up = 0.0;
         HC_nc = 1.0;
         }
     HC_down = 1 - HC_up - HC_nc;

	 decl vv = CV(HC.v),
 		q = (vv ?  HC_down ~ (vv < HC.N-1 ? HC_nc~HC_up : (HC_nc+HC_up)) : (HC_down+HC_nc)~HC_up);
     return q;
}
*/


 /*
/**Transition of Credits**/
QualityConstraints_2::Cr_Transit(FeasA){
	decl prob_fail, prob_pass, prob_down;

	decl Age = curt + Age0;
	
  	if(CV(GROWNUp) == 0){
		decl ivals_work = FeasA[][work.pos], ivals_attend = FeasA[][attend.pos]; 
	    prob_pass = ivals_attend .? (theta_0 + theta_1*CV(Abil) + theta_5*(ivals_work.==0) + theta_6*(ivals_work.==.5) + theta_7*(ivals_work.==1)) .: 0;
		 }
	else{
		prob_pass = 0;
	}
	prob_down = 0;
	prob_fail = 1 - prob_pass;
		
	decl qq = CV(Credits.v),
		v = (qq ? prob_down ~ (qq < Credits.N-1 ? prob_fail~prob_pass : (prob_fail + prob_pass)) : (prob_down + prob_fail) ~ prob_pass);
	return v;	

}
*/
  /*
QualityConstraints_2::Savings(FeasA){
	//println
	return savings.actual[FeasA[][savings.pos]]';
	}
*/ 

QualityConstraints_2::Utility() {

	if (curt==TMax-1 || curt==0) return zeros(rows(A[Aind]),1);

//	wage = ((omega_1) + (omega_2)*CV(HC))*52 .*(work.actual[aa(work)]');
	wage = ((omega_1) + (omega_2))*52 .*(work.actual[aa(work)]');
 
	decl cons =	wage; // - savings.actual[aa(savings)]'; /*Consumption*/

	/*Total one period utility*/
	decl util = cons .<= 0.0 .? -.Inf .:  (cons.^(1-rho))/(1-rho) + aa(work)*gamma_22;

	return util;
	}
	