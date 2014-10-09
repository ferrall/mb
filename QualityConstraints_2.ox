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
		borrow = new ActionVariable("loans", MaxScAssets),
	 	GrowUp = new ActionVariable("GrowUp", MPhaselabel)); //,

	work.actual = <0.0;0.5;1.0>;
	borrow.actual = <0.0; 3000.0; 6000.0>;
	savings.actual = <0.0; 1000.0; 5000.0; 10000.0; 20000.0>;

/**State Variables:**/

//ENDOGENOUS STATES:

	EndogenousStates(
		GROWNUp = new PermanentChoice("GROWNUp", GrowUp),		
		Credits=  new Forget(new RandomUpDown("Credits", MaxCredits, QualityConstraints_2::Cr_Transit),GROWNUp,Forgotten),
		SchoolType = new Forget(new PermanentChoice("SchoolType", schoice)
					,GROWNUp,Forgotten),
		asset = new Asset("asset", MaxAssets, r, QualityConstraints_2::Savings),
	//	Sch_loans = new Forget(new Asset("Sch_loans", MaxScAssets, r1, QualityConstraints_2::Loans),
	//				Event(), Forgotten),
		Sch_loans = new Asset("Sch_loans", MaxScAssets, r1, QualityConstraints_2::Loans),
		HC = new Freeze(new RandomUpDown("HC", MaxHC, QualityConstraints_2::HC_trans), QualityConstraints_2::Event())		   //Event needs to be an age. 
					);
	asset.actual = savings.actual;

//EXOGENOUS STATES:
 
	ExogenousStates(
	//	leisure = new SimpleJump("g",3),
		wageoffer = new Zvariable("w",Noffers),
		gshocks = new MVNormal("eps", Ngrants, Noffers, zeros(Ngrants,1),sig)
		);
 
 
//Fixed Effects:
	GroupVariables(
		Abil = new FixedEffect("abil", MAbillabel),
		Race = new FixedEffect("race", MRacelabel),
		Score = new FixedEffect("score", 1), 	//MScorelabel
		Wealth = new FixedEffect("wealth", 1),	//MWealthlabel
		Inc = new FixedEffect("income", 1), 		//MInclabel
		Nsib = new FixedEffect("nsib", 1)	//sibling in college or not. 
			   );

			   
//	Volume = LOUD;
	CreateSpaces();
	decl Emax = new ValueIteration();
	Emax -> Solve();
	PD = new PanelPrediction(0);
	PD -> Predict(TMax);
	PD -> Histogram(HC,TRUE,TRUE);
	PD -> Histogram(GrowUp,TRUE,TRUE);
	PD -> Histogram(Credits,TRUE,TRUE);
	PD -> Histogram(attend,TRUE,TRUE);
	PD -> Histogram(borrow,TRUE,TRUE);
	PD -> Histogram(savings,TRUE,TRUE);
//	PD -> Histogram(GROWNUp,TRUE,TRUE);
	delete PD;
}

/**CONSTRAINTS ON CHOICE:**/
QualityConstraints_2::FeasibleActions(const Alpha) {

//there is a mistake here, in some phase you cannot attend, but you can borrow
	
	decl Age = curt + Age0, A;

	//Need to clean up below: Basically -> if school choice is 0, you have to grow up in the initial period. 
	if (Age == Age0) return (!Alpha[][attend.pos] .* !Alpha[][work.pos] .* !Alpha[][savings.pos].* !Alpha[][borrow.pos])
							.*!(Alpha[][GrowUp.pos].*Alpha[][schoice.pos]).*(1 - (!Alpha[][GrowUp.pos].*!Alpha[][schoice.pos]));

	A = (Alpha[][schoice.pos].==0);

//	A = !( CV(GROWNUp) + Alpha[][schoice.pos] )            //After t=0, no choice
//		+ CV(GROWNUp).*(Alpha[][schoice.pos].==Forgotten|| !Alpha[][attend.pos]); //After GROWNUp, no choice, but forgotten state

	if (curt >= MaxTAtt) A .*= (Alpha[][GrowUp.pos]);  	/*Must grow up at certain age*/

	if (CV(GROWNUp) == 1) {
		A .*= (Alpha[][GrowUp.pos].==Older); 
		A .*= (Alpha[][attend.pos].==NoAttend);  	/*rule out school attendance when grownup = 0*/
		A .*= (Alpha[][borrow.pos].==0);	/*would need to change if change grid points*/
		}
	else{
		A .*= (Alpha[][savings.pos].==0);	 /*Would need to change if i change the grid points for savings*/
		A .*= 1 - (!Alpha[][attend.pos]).*!(!Alpha[][borrow.pos]);
		}

//	if (curt >= TMax-2) A.*= (Alpha[][work.pos].==FullWork); //work full-time only
	
	return A;
	}

QualityConstraints_2::Reachable() {

	if (curt == 0) {
			if (CV(GROWNUp) || !(CV(Sch_loans)==0) || !(CV(asset)==0) || !(CV(Credits)==0) || !(CV(SchoolType)==0) ) return 0;
			}
			//cant be grown up in initial decision
			//can't be mature worker in inital decision
			//can't start off with student loans
			//Can't have assets in initial decision
			
			
	//first phase
	if (CV(Credits) > curt) return 0;
			
	if ( (curt > MaxTAtt || CV(GROWNUp) ) && ( CV(SchoolType)!=Forgotten || CV(Credits)!=Forgotten ) ) return 0;

	if (curt == TMax-2) {
		if (CV(Sch_loans)||CV(Credits)||CV(SchoolType)||!CV(GROWNUp)) return 0; //forget student loans once older worker, the other two already forgotten.
			}

//	if (curt == TMax-1) return 0;  //never die
	
	return new QualityConstraints_2();
	}

QualityConstraints_2::HC_trans(FeasA) {
     decl HC_up, HC_nc, HC_down;

//     Now RandomUpDown always takes 3 prob.
	if(!GROWNUp.v){
    HC_up = (FeasA[][attend.pos].==1).*(phi_0 + phi_1*(SchoolType.v==1) + phi_2*(SchoolType.v==2) + phi_3*(SchoolType.v==3) + phi_4*(SchoolType.v==4));
    HC_nc = phi_0 + phi_1*(SchoolType.v==1) + phi_2*(SchoolType.v==2);																										   
	}
	else{
    HC_up = beta_0 + beta_1*(FeasA[][work.pos].==0) + beta_2*(FeasA[][work.pos].==1);
    HC_nc = beta_0 + beta_1*(FeasA[][work.pos].==0) + beta_2*(FeasA[][work.pos].==1) + beta_3*(FeasA[][work.pos].==2);	
	}
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

QualityConstraints_2::Loans(FeasA){
	decl th = Settheta(ind[tracking]);
	return th->Budget(FeasA);	
	}
	
//Net savings for school loans
QualityConstraints_2::Budget(FeasA) {
	gross = net_tuition = n_loans = 0.0;
	if (curt==0) return 0;
	
	decl BA = 0, Age = Age0 + curt, sch_repayment;
	decl stype = CV(SchoolType), score = CV(Score), schloans = Sch_loans.actual[CV(Sch_loans)];	//getting values 
	decl att1 = FeasA[][attend.pos], wrk1 = FeasA[][work.pos], sav1 = FeasA[][borrow.pos];
//	decl wage_shock = wagesig*AV(wageoffer);

	 /*Wages*/
	wage = (wrk1.==0) .? ((omega_1) + (omega_2)*CV(HC))*52
	          //        .: (CV(HC)*exp(alpha_0+alpha_1*(wrk1.==1) + alpha_2*att1 + alpha_3*CV(Race) + wage_shock))*hours*weeks.*AV(wrk1)/2; //yearly wages too high right now
					  .: (CV(HC)*exp(alpha_0+alpha_1*(wrk1.==1) + alpha_2*att1 + alpha_3*CV(Race)))*hours*weeks.*AV(wrk1)/2; 
	/*Parental Transfers*/
	transfers = (curt>=TMax-2) ? 0 : chi_0 + chi_1*att1 + chi_2*att1*CV(Wealth) + chi_3*(CV(Credits) + 12) + chi_4*Age + chi_7*CV(HC) + chi_8*CV(Race) + chi_10*AV(wrk1);
	gross = AV(asset) + wage + transfers;

//Not taking into account wages etc etc. where should this be done?
//	A.*= 1 - (asset.actual[asset.v] + savings.actual[savings.pos] .< B_Limit_Sav);

	if(!CV(GROWNUp)){
		/*Tuition & Grants*/
		decl grants= 
			setbounds(
				tau* (1|CV(Race)|CV(Inc)|CV(Wealth)|(score==1)|(score==2)|CV(Nsib)|((score==1)&&(stype==2))|((score==2)&&(stype==2))|(stype==1) | 0.0 )  //4 year
				+ AV(gshocks)'
				,0.0,+.Inf);
		//no one is getting grants right now with these parameter values
		net_tuition = (tau_0[stype] - sumc(grants))*att1;
		n_loans = 0.0;
		return borrow.actual[FeasA[][borrow.pos]];
		}
	else {
		net_tuition = 0.0;
		if (curt>=TMax-3) return -schloans; //so if loans are > 0 when transitioning to old age, it goes to zero. 
		sch_repayment = (schloans)/(1 - (1/(1+r1))^(TMax-2 - curt))/(1-(1/(1+r1))); //denominator is a geometric series
		n_loans = (gross .< sch_repayment) .? mu*schloans .: -sch_repayment;	//see if in default or not, choose the correct transition
		return n_loans;
		}
	}

 
QualityConstraints_2::Savings(FeasA){
	//println
	return savings.actual[FeasA[][savings.pos]];
	}

QualityConstraints_2::Event() {
	return (curt >= TMax-2);
	}
	
	QualityConstraints_2::Utility() {

	if (curt==TMax-1 || curt==0) return zeros(rows(A[Aind]),1);

	decl cons =	/*Consumption*/
		//gross - net_tuition - n_loans - savings.actual[aa(savings)]' + borrow.actual[aa(borrow)]'; //not right?
		//net-savings is state-and action-dependent change in asset holding:
		wage + transfers - net_tuition - n_loans - savings.actual[aa(savings)]' + borrow.actual[aa(borrow)]'; //is this right?

	/*Total one period utility*/
	decl util = cons .<= 0.0 .? -.Inf .:  (cons.^(1-rho))/(1-rho) + aa(attend)*gamma_20 + aa(work)*gamma_22;

	return util;
	}

	//age, fixed effects condition on those to get moments ->
	//wage, wage^2

	//1 ) data files for niqlow

	//auxillary

	//compute in panel correlation between th momemnts  or contemporaneous

	// 2) data set for calculating moments 
	