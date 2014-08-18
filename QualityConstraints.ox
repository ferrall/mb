#include "QualityConstraints.h"
#define RandomHumanCapital  //uncomment if want to use unobserved state variable
//#define KWApprox //uncomment if using KW

QualityConstraints::Replicate(){

decl KW;

Initialize(1.0,Reachable, TRUE, 0);
SetClock(UncertainLongevity,TMax,0.0);
SetDelta(0.97);

/**Actions**/
	Actions(
		work = new ActionVariable("work", MWorklabel), //work
		attend = new ActionVariable("attend", MAttendlabel), //attend school
	 	GrowUp = new ActionVariable("GrowUp", MPhaselabel),  
		savings = new ActionVariable("savings", MaxAssets),
		borrow = new ActionVariable("loans",3),
		schoice = new ActionVariable("schoice", MSchooltype) //school choice
	);

	borrow.actual = <0.0, 3000.0, 6000.0 >;
	savings.actual = <0.0, 1000.0, 5000.0, 10000.0, 20000.0>;
	work.actual = <0.0,0.5,1.0>;

/**State Variables:**/

//EXOGENOUS STATES: (right now not correlated. Need to add grant shocks - both general and specific). 
	ExogenousStates(
//		leisure = new SimpleJump("g",3),
		wageoffer = new Zvariable("w",Noffers),
		gshocks = new MVNormal("eps", Ngrants, Noffers, zeros(Ngrants,1),sig)
		);
		
//	leisure.actual = -leisuresig ~ 0.0 ~ leisuresig;
	

//ENDOGENOUS STATES:
#ifdef RandomHumanCapital
	EndogenousStates(
 		HC = new RandomUpDown("HC", MaxHC, QualityConstraints::HC_trans),				
		Credits= new RandomUpDown("Credits", MaxCredits, QualityConstraints::Transit),
		//	BA = new Deterministic("BA", 1, QualityConstraints::Degree_Status),	 //should this be in a state block with credits..right?
		Sch_loans = new Asset("Sch_loans", MaxScAssets, r1, QualityConstraints::Loans),
		asset = new Asset("asset", MaxAssets, r, QualityConstraints::Savings), 
		GROWNUp = new LaggedAction("GROWNUp", GrowUp),
//	    OldWorker = new StateCounter("OldWorker", MaxYrsWrk+MaxTAtt, GROWNUp, 1, 0), //Once it hits 10, workers enter 3rd phase, but need to edit once default is included
		SchoolType = new PermanentChoice("SchoolType", schoice));

	asset.actual = <0.0, 1000.0, 5000.0, 20000.0, 50000.0>;
	Sch_loans.actual = <0.0, 1000.0, 5000.0, 20000.0, 50000.0>;
		
#else

	EndogenousStates(
  		xper = new ActionAccumulator("xper", MaxXper, work), //adds 1 for part-time, 2 for full-time, max of 10 years of experience, but this should only increase if in phase 1. 				
		Credits= new RandomUpDown("Credits", MaxCredits, QualityConstraints::Transit),
		//Sch_loans = ActionAccumulator("Sch_Loans", Sch_borrowing),
		assets = new LaggedAction("assets", savings), //Need appropriate transtion
		GROWNUp = new ActionTracker("GROWNUp", GrowUp, 1), 
		SchoolType = new PermanentChoice("SchoolType", schoice));
#endif

//FIXED EFFECTS
	GroupVariables(Abil = new FixedEffect("abil", MAbillabel),
			   Race = new FixedEffect("race", MRacelabel),
			   Score = new FixedEffect("score", 1), 	//MScorelabel
			   Wealth = new FixedEffect("wealth", 1),	//MWealthlabel
			   Inc = new FixedEffect("income", 1), 		//MInclabel
			   Nsib = new FixedEffect("nsib", 1)	//sibling in college or not. 
			   );
	
#ifdef KWApprox	
	CreateSpaces();
	Volume = SILENT;
	KW = new KeaneWolpin(ones(1,10)~constant(0.1,1,A1-10),0);
	KW.Volume = SILENT;
	KW -> Solve();
#else
	CreateSpaces();
	Volume = SILENT;
	decl Emax = new ValueIteration(0);
	Emax.Volume = SILENT;
	Emax -> Solve(0,0);
#endif

}

/**CONSTRAINTS ON CHOICE:**/
QualityConstraints::FeasibleActions(const Alpha) {
	
	decl Age = curt + Age0, A;

	decl Borrow_Limit = 0; //calculate state-dependent borrowing limit here. 

	/*Only choice in first period, is which school*/
//	if (Age == Age0) return !any(Alpha[][attend.pos~work.pos~savings.pos~GrowUp.pos]);
	if (Age == Age0) return !Alpha[][attend.pos] .* !Alpha[][work.pos] .* !Alpha[][savings.pos] .* !Alpha[][GrowUp.pos]
							.* !Alpha[][borrow.pos];

	/*Do not choose school-type after first period*/
	A = (Alpha[][schoice.pos].==0);

	/*Cannot choose to grow up and attend school*/
	A .*= 1 - (Alpha[][attend.pos]).*(Alpha[][GrowUp.pos]);
// redundant??	A .*= 1 - (Alpha[][borrow.pos].>0).*(Alpha[][saving.pos].>0);

	/*Cannot attend school if school type is 0*/
	if (SchoolType.v == 0) A .*= (Alpha[][attend.pos].==0);  //this doesn't decrease total states, just shifts between columns
	
	if (curt > MaxTAtt)  {
		A .*=  (Alpha[][attend.pos].==0);   /*rule out schooling if too old*/
		A .*= (Alpha[][GrowUp.pos].==1);  	/*Must grow up at certain age*/
		}

	/*If already GROWNUP, must choose GrowUp every period*/
	if (GROWNUp.v == 1) {
		A .*= (Alpha[][GrowUp.pos].==1); 
		A .*= (Alpha[][attend.pos].==0);  	/*rule out school attendance when grownup = 0*/
		A .*= (Alpha[][borrow.pos].==0);
		}
	else
		A .*= Alpha[][savings.pos].==0;

	/*Need to limit feasible savings*/

	/*Cannot use student loans to save in first period, can only borrow*/
//	if(GROWNUp.v == 0) A.*= (Alpha[][savings.pos] .<= 2);

	/*Old Age: No work choice, all full-time*/
//	if(OldWorker.v == 10) A.* (Alpha[][work.pos].==2); //work full-time, can choose savings, that's it (because of GROWNUP==1 conditions above)

	/*Need to rule out school borrowing while not attending*/
	if(SchoolType.v != 0 && GROWNUp.v == 0) A.*= 1 - (Alpha[][attend.pos] == 0).*(Alpha[][savings.pos] != 0);

	return A;
	}  
	 
QualityConstraints::Reachable() {
	//CF: many other unreachable states
#ifdef RandomHumanCapital
		decl MaxEarned = curt, Cr = Credits.v;

		//inital decision
		if (curt == TMax-1) return 0;  //never die
		if (curt == TMax-2) {
			if (CV(Sch_loans)||CV(Credits)||CV(SchoolType)||!CV(GROWNUp)) return 0; //forget student loans once older worker, the other two already forgotten.
			}
		if (curt == 0) {
			if (CV(GROWNUp) || !(CV(Sch_loans)==0) || !(CV(asset)==0) || !(CV(Credits)==0) || !(CV(SchoolType)==0) ) return 0; 
			//cant be grown up in initial decision
			//can't be mature worker in inital decision
			//can't start off with student loans
			}
		if (!CV(GROWNUp)) {
		   if (CV(asset) || curt>MaxTAtt) return 0;
		   }
		//first phase
		if (CV(Credits) > curt) return 0;	 //Need to edit this once more than 1 credit a year (covers first phase as well)

		//second phase
		if (CV(GROWNUp) ) {
			if (CV(Credits) || CV(SchoolType) ) return 0;	//forget credits when grown-up.//forget school type one working age
			}

		//third phase
		return new QualityConstraints();
#else
		decl MaxEarned = curt, MaxExp = curt, Cr = Credits.v, yrs_exp = (xper.v)/2;		
		if (Credits.v > curt) return 0; 
		if (yrs_exp > curt) return 0;   		
		return new QualityConstraints();
#endif
}

/*Transition of Random Human Capital*/

#ifdef RandomHumanCapital	//based on school attendance, simple up or down  
QualityConstraints::HC_trans(FeasA) {
	decl ivals_work = FeasA[][work.pos];
	decl ivals_attend = FeasA[][attend.pos];
	decl school_quality = SchoolType.v, Grownup = GROWNUp.v;
	decl Learning_up, Learning_nc, Experience_up, Experience_nc, HC_up, HC_nc, HC_down;

	if(curt<TMax-2){
		//Experience = probability of going up due to experience: Depends on working (ft vs pt vs not), ability
		Experience_up = beta_0.*Abil.v + beta_1.*(ivals_work==0) + beta_2.*(ivals_work==1) + beta_3.*(ivals_work==2);
		Experience_nc = beta_0.*Abil.v + beta_1.*(ivals_work==0) + beta_2.*(ivals_work==1) + beta_3.*(ivals_work==2);
		//Learning = probability of going up due to learning: Depends on school/attendance/passing the year, if you're working, ability
		Learning_up = beta_4.*(school_quality==1).*(ivals_attend.==1) + beta_5.*(school_quality==2).*(ivals_attend.==1) + beta_6.*(school_quality==3).*(ivals_attend==1) + beta_7.*(school_quality==4).*(ivals_attend==1);
		Learning_nc = beta_4.*(school_quality==1).*(ivals_attend.==1) + beta_5.*(school_quality==2).*(ivals_attend.==1) + beta_6.*(school_quality==3).*(ivals_attend==1) + beta_7.*(school_quality==4).*(ivals_attend==1);

		//Should not accumulate once you are "old age"
		HC_up = (1 - Grownup)*Learning_up + (Grownup)*Experience_up;	 //	(OldWorker.v != 10)*((1 - Grownup)*Learning + (Grownup)*Experience) + 	(OldWorker.v != 10)*0;
		HC_nc = (1 - Grownup)*Learning_nc + (Grownup)*Experience_nc; //need to update this.
		HC_down = 1 - HC_up - HC_nc; //(OldWorker.v != 10)*(1 - HC_up - HC_nc) + (OldWorker.v == 10)*0; 
		return HC_up~HC_nc~HC_down;
	}
	else{
	 	return 0~1~0;
	}
}
#endif

//Net savings for regular asset
QualityConstraints::Savings(FeasA){
	return savings.actual[FeasA[][savings.pos]]';
	}

QualityConstraints::Loans(FeasA){
	decl th = Settheta(ind[tracking]);
	return th->Budget(FeasA);	
	}
	
//Net savings for school loans
QualityConstraints::Budget(FeasA) {
	gross = net_tuition = n_loans = 0.0;
	if (curt==0) return 0;
	
	decl disu, wage, BA = 0, Age = Age0 + curt, transfers, age = curt + Age0;
	decl stype = SchoolType.v, assets = asset.v, black = Race.v, wealth = Wealth.v, inc = Inc.v,
	ability = Abil.v, score = Score.v, nsib = Nsib.v, schloans = Sch_loans.actual[Sch_loans.v];	//getting values 
	decl att1 = FeasA[][attend.pos], wrk1 = FeasA[][work.pos], sav1 = FeasA[][borrow.pos];

	decl wage_shock = wagesig*AV(wageoffer);

	decl r2, a, n, geo_series, sch_repayment;

	 /*Wages*/
	wage = (wrk1.==0) .? (omega_1)
	                  .: (CV(HC)*exp(alpha_0+alpha_1*(wrk1.==1) + alpha_2*att1 + alpha_3*black + wage_shock)); //yearly wages too low right now

	/*Parental Transfers*/
	transfers = (curt>=TMax-2) ? 0 : chi_0 + chi_1*att1 + chi_2*att1.*wealth + chi_3*(CV(Credits) + 12) + chi_4*Age + chi_7*CV(HC) + chi_8*black + chi_10*wrk1;
	gross = AV(asset) + wage + transfers;

	
/*Transition:
1)	When in School: Just the amount you borrow
2) If grownup, depends whether you go into default or not: goes up my mu if in default, otherwise normal repayment
3) If an old worker, it needs to transition to 0. Need to recheck this. 
*/
	if(!CV(GROWNUp)){
		/*Tuition & Grants*/
		decl grants= 
			setbounds(
				tau* (1|black|inc|wealth|(score==1)|(score==2)|nsib|((score==1)&&(stype==2))|((score==2)&&(stype==2))|(stype==1) | 0.0 )  //4 year
				+ AV(gshocks)'
				,0.0,+.Inf);
		//no one is getting grants right now with these parameter values
		net_tuition = (tau_0[stype] - sumc(grants))*att1;
		n_loans = 0.0;
		return borrow.actual[FeasA[][borrow.pos]]';
		}
	else {
		net_tuition = 0.0;
		if (curt>=TMax-3) return -schloans; //so if loans are > 0 when transitioning to old age, it goes to zero. 
		r2 = 1/(1+r1);
		geo_series = (1 - r2^(TMax-2 - curt))/(1-r2);
		sch_repayment = (schloans)/geo_series; //denominator is a geometric series
		n_loans = (gross .< sch_repayment) .? mu*schloans .: -sch_repayment;	//see if in default or not, choose the correct transition
		return n_loans;
		}
	}

//**Transition of Credits**//
QualityConstraints::Transit(FeasA){

	if(GROWNUp.v == 0){
		decl ivals_work = FeasA[][work.pos], ivals_attend = FeasA[][attend.pos];
		decl ability_1 = Abil.v;
		decl pi_f = theta_1.*ability_1 + theta_3.*curt + theta_5.*(ivals_work.==0) + (theta_5 + theta_6).*(ivals_work.<=.5) + (theta_5 + theta_6 + theta_7).*(ivals_work.==1); 
		decl prob_fail = 1/(1+exp(pi_f)); 
		return 0~(prob_fail)~(1-prob_fail); //stay the same, up 1, down 1
	}
	else{
		return 0~1~0; //No transition on credits when grownup. 
	}

}
/*One Period Return*/

QualityConstraints::Utility() {

	if (curt==TMax-1 || curt==0) return zeros(rows(A[Aind]),1);

	/*Getting values for i.i.d. shocks (can clean this up later)*/
	decl cons =	/*Consumption*/
		gross - net_tuition - n_loans - aa(savings) + aa(borrow);  //??

	/*Total one period utility*/
	decl util = cons .<= 0.0 .? -.Inf .:  (cons.^(1-rho))/(1-rho) + aa(attend)*gamma_20 + aa(work)*gamma_22;  //Danger!!!!
	if (!any(util .!= -.Inf)) {
		println(curt," ",CV(HC)," ",CV(asset)," ",CV(GROWNUp)," ",CV(Sch_loans)," ",net_tuition," ",n_loans," ",gross,util');
		}

	return util;
	}
	
/*
Need to add:
0) Finding errors.
1)
	a) Borrowing limits - function of current states - age and human capital?
	b) make sure consumption has to be positive. 
3) Degree status - needs to be in a state block with credits?
4) Years in the second phase - need to add 5 if you end up defaulting - not sure how to do this?
5) different interest rates for borrowing and saving?
6) use functions for the repayment and wages that end up being used over and over again?
7) Need to fix human capital probabilities
*/
