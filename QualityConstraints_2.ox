#include "QualityConstraints_2.h"

QualityConstraints_2::Replicate(){

decl KW, PD;

Initialize(1.0,Reachable, TRUE, 0);
//SetClock(UncertainLongevity,TMax,0.0);
SetClock(NormalAging,TMax-2);
SetDelta(0.95);

/**Actions**/
	Actions(
		work = new ActionVariable("work", MWorklabel),
		attend = new ActionVariable("attend", MAttendlabel), //attend school
	 	GrowUp = new ActionVariable("GrowUp", MPhaselabel),
		schoice = new ActionVariable("schoice", MSchooltype), //); //school choice; //,
		savings = new ActionVariable("savings", MaxAssets));

	work.actual = <0.0,0.5,1.0>;
	savings.actual = <0.0, 1000.0, 5000.0, 10000.0, 20000.0>;

/**State Variables:**/

//ENDOGENOUS STATES:

	EndogenousStates(
 		HC = new RandomUpDown("HC", MaxHC, QualityConstraints_2::HC_trans),
		Credits= new RandomUpDown("Credits", MaxCredits, QualityConstraints_2::Transit),
		GROWNUp = new LaggedAction("GROWNUp", GrowUp),
		SchoolType = new PermanentChoice("SchoolType", schoice), //); //,
		asset = new Asset("asset", MaxAssets, r, QualityConstraints_2::Savings));

		ExogenousStates(
//		leisure = new SimpleJump("g",3),
		wageoffer = new Zvariable("w",Noffers),
		gshocks = new MVNormal("eps", Ngrants, Noffers, zeros(Ngrants,1),sig)
		);

	GroupVariables(Abil = new FixedEffect("abil", MAbillabel),
			   	   Race = new FixedEffect("race", MRacelabel),
			       Score = new FixedEffect("score", 1), 	//MScorelabel
			       Wealth = new FixedEffect("wealth", 1),	//MWealthlabel
			       Inc = new FixedEffect("income", 1), 		//MInclabel
			       Nsib = new FixedEffect("nsib", 1)	//sibling in college or not. 
			   	   );
	
	CreateSpaces();
//	Volume = NOISY;
	decl Emax = new ValueIteration(0);
//	Emax.Volume = NOISY;
	Emax -> Solve(0,0);
	PD = new PanelPrediction(0);
	PD -> Predict(22);
	PD -> Histogram(work,TRUE,TRUE);
	delete PD;
}

/**CONSTRAINTS ON CHOICE:**/
QualityConstraints_2::FeasibleActions(const Alpha) {
	
	decl Age = curt + Age0, A;

	if (Age == Age0) return !Alpha[][attend.pos] .* !Alpha[][work.pos] .* !Alpha[][GrowUp.pos];
	//if (Age == Age0) return !Alpha[][attend.pos] .* !Alpha[][work.pos] .* !Alpha[][savings.pos] .* !Alpha[][GrowUp.pos].* !Alpha[][borrow.pos];
	A = (Alpha[][schoice.pos].==0);

	A .*= 1 - (Alpha[][attend.pos]).*(Alpha[][GrowUp.pos]);	//
	
	if (CV(SchoolType) == 0) A .*= (Alpha[][attend.pos].==0);

	if (curt > MaxTAtt)  {
		A .*=  (Alpha[][attend.pos].==0);   /*rule out schooling if too old*/
		A .*= (Alpha[][GrowUp.pos].==1);  	/*Must grow up at certain age*/
		}

	/*If already GROWNUP, must choose GrowUp every period*/
	if (CV(GROWNUp) == 1) {
		A .*= (Alpha[][GrowUp.pos].==1); 
		A .*= (Alpha[][attend.pos].==0);  	/*rule out school attendance when grownup = 0*/
//		A .*= (Alpha[][borrow.pos].==0);	/*would need to change if change grid points*/
		}
//	else
//		A .*= Alpha[][savings.pos].==0;	 /*Would need to change if i change the grid points for savings*/

	if(curt == TMax-2) A.* (Alpha[][work.pos].==2); //work full-time only

	
	return A;
	}

QualityConstraints_2::Reachable() {

		return new QualityConstraints_2();
}

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

QualityConstraints_2::Transit(FeasA){
	decl prob_fail, prob_pass, prob_down;

	decl Age = curt + Age0;
	
  	if(CV(GROWNUp) == 0){
		decl ivals_work = FeasA[][work.pos], ivals_attend = FeasA[][attend.pos]; 
	//	prob_pass = theta_0 + theta_1*CV(Abil) + theta_2*curt + theta_5*(ivals_work.==0) + (theta_6)*(ivals_work.<=.5) + (theta_7)*(ivals_work.==1);
		prob_pass = theta_0 + theta_1*CV(Abil) + theta_5*(ivals_work.==0) + theta_6*(ivals_work.==.5) + theta_7*(ivals_work.==1);
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

QualityConstraints_2::Savings(FeasA){
	return savings.actual[FeasA[][savings.pos]]';
	}
 

//**Transition of Credits**//

QualityConstraints_2::Utility() {

	if (curt==TMax-1 || curt==0) return zeros(rows(A[Aind]),1);

	wage = ((omega_1) + (omega_2)*CV(HC))*52.*aa(work);

	decl cons =	wage; // - savings.actual[aa(savings)]'; /*Consumption*/

	/*Total one period utility*/
	decl util = cons .<= 0.0 .? -.Inf .:  (cons.^(1-rho))/(1-rho) + aa(work)*gamma_22;

	return util;
	}
	