#include "QualityConstraints.h"
#define RandomHumanCapital  //uncomment if want to use unobserved state variable
//#define KWApprox //uncomment if using KW

QualityConstraints::Replicate(){

decl KW;

Initialize(Reachable, TRUE, 0);
SetClock(NormalAging,A1);
SetDelta(0.97);

/**Actions**/
	Actions(
		work = new ActionVariable("work", MWorklabel), //work
		attend = new ActionVariable("attend", MAttendlabel), //attend school
	 	GrowUp = new ActionVariable("GrowUp", MPhaselabel),  
		savings = new ActionVariable("savings", MaxAssets),  
		schoice = new ActionVariable("schoice", MSchooltype) //school choice
	);

	savings.actual = <0.0, 1000.0, 5000.0, 10000.0, 20000.0>;

/**State Variables:**/

//EXOGENOUS STATES: (right now not correlated. Need to add grant shocks - both general and specific). 
	ExogenousStates(shocks = new MVNormal("eps", 5, Noffers, zeros(5,1),sig));

//ENDOGENOUS STATES:
#ifdef RandomHumanCapital
	EndogenousStates(
 		HC = new RandomUpDown("HC", MaxHC, QualityConstraints::HC_trans),				
		Credits= new RandomUpDown("Credits", MaxCredits, QualityConstraints::Transit),
		//	BA = new Deterministic("BA", 1, QualityConstraints::Degree_Status),	 //should this be in a state block with credits..right?
		Sch_loans = new Asset("Sch_loans", MaxScAssets, r1, QualityConstraints::Loans),
		asset = new Asset("asset", MaxAssets, r, QualityConstraints::Savings), 
		GROWNUp = new LaggedAction("GROWNUp", GrowUp),
	    OldWorker = new StateCounter("OldWorker", MaxYrsWrk, GROWNUp, 1, 0), //Once it hits 10, workers enter 3rd phase, but need to edit once default is included
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
	CreateSpaces(LogitKernel,1/4000.0);
	Volume = SILENT;
	KW = new KeaneWolpin(ones(1,10)~constant(0.1,1,A1-10),0);
	KW.Volume = SILENT;
	KW -> Solve();
#else
	CreateSpaces(LogitKernel,1.0);
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
	if (Age == Age0) return !Alpha[][attend.pos] .* !Alpha[][work.pos] .* !Alpha[][savings.pos] .* !Alpha[][GrowUp.pos];

	/*Do not choose school-type after first period*/
	A = (Alpha[][schoice.pos].==0);

	/*Cannot choose to grow up and attend school*/
	A .*= 1 - (Alpha[][attend.pos]).*(Alpha[][GrowUp.pos]);

	/*Cannot attend school if school type is 0*/
	if (SchoolType.v == 0) A .*= (Alpha[][attend.pos].==0);  //this doesn't decrease total states, just shifts between columns

	/*rule out schooling if too old*/
	if (Age > MaxAgeAtt)  A .*=  (Alpha[][attend.pos].==0);

	/*Must grow up at certain age*/
	if (Age > MaxAgeAtt) A .*= (Alpha[][GrowUp.pos].==1);

	/*If already GROWNUP, must choose GrowUp every period*/
	if (GROWNUp.v == 1) A .*= (Alpha[][GrowUp.pos].==1); 

	/*rule out school attendance when grownup = 0*/
	if(GROWNUp.v == 1) A.*= (Alpha[][attend.pos].==0);

	/*Need to limit feasible savings*/

	/*Cannot use student loans to save in first period, can only borrow*/
	if(GROWNUp.v == 0) A.*= (Alpha[][savings.pos] .<= 2);

	/*Old Age: No work choice, all full-time*/
	if(OldWorker.v == 10) A.* (Alpha[][work.pos].==2); //work full-time, can choose savings, that's it (because of GROWNUP==1 conditions above)

	/*Need to rule out school borrowing while not attending*/
	if(SchoolType.v != 0 && GROWNUp.v == 0) A.*= 1 - (Alpha[][attend.pos] == 0).*(Alpha[][savings.pos] != 0);

	return A;
	}  
	 
QualityConstraints::Reachable() {
	//CF: many other unreachable states
#ifdef RandomHumanCapital
		decl MaxEarned = curt, Cr = Credits.v;

		//inital decision
		if (curt == 0 && GROWNUp.v == 1) return 0; //cant be grown up in initial decision
		if (curt == 0 && OldWorker.v == 1) return 0; //can't be mature worker in inital decision
		if (curt == 0 && Sch_loans.v !=0) return 0; //can't start off with student loans
		
		//first phase
		if (Credits.v > curt) return 0;	 //Need to edit this once more than 1 credit a year (covers first phase as well)
		if (!GROWNUp.v && asset.v!= 0 ) return 0; // no assets before growing up (covers, inital period as well with with first condition)
		if (!GROWNUp.v && OldWorker.v != 0) return 0; //cannot be young, and also begun counting (not sure if built in).

		//second phase
		if (Credits.v > 0 && GROWNUp.v == 1) return 0;	//forget credits when grown-up.
		if (SchoolType.v > 0 && GROWNUp.v ==1) return 0; //forget school type one working age 

		//third phase
		if (OldWorker.v == 10 && Sch_loans.v > 0) return 0; //forget student loans once older worker, the other two already forgotten.
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

	if(OldWorker.v < 10){
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
		return HC_nc~HC_up~HC_down;
	}
	else{
	 	return 1~0~0;
	}
}
#endif

//Net savings for regular asset
QualityConstraints::Savings(FeasA){

	decl n_savings;

	if(GROWNUp.v == 1){	  //only can have savings if GrownUp
		n_savings = savings.actual[FeasA[][savings.pos]]';
		}
	else{
		n_savings = zeros(rows(FeasA),1);	//no saving when not grownup. 
	}
return n_savings; 	 
}

//Net savings for school loans
QualityConstraints::Loans(FeasA){

	decl n_loans;

	decl disu, wage, BA = 0, H_C, Age = Age0 + curt, transfers, age = curt + Age0;
	decl Cr = Credits.v, stype = SchoolType.v, assets = asset.v, epsil = shocks.v, black = Race.v, wealth = Wealth.v, inc = Inc.v,
	ability = Abil.v, score = Score.v, nsib = Nsib.v, schloans = Sch_loans.actual[Sch_loans.v];	//getting values 
	decl att1 = FeasA[][attend.pos], wrk1 = FeasA[][work.pos], sav1 = FeasA[][savings.pos];

	decl wage_shock = shocks.Grid[2][epsil[2]];
	decl gen_grants_shock = shocks.Grid[3][epsil[3]];
	decl spec_grants_shock = shocks.Grid[4][epsil[4]];

	decl r2, a, n, geo_series, sch_repayment;


 /*Human capital & Wages & parental transfers*/
#ifdef RandomHumanCapital
	H_C = HC.v;
	 /*Wages*/
	wage = (wrk1.==0).*(omega_1) + (wrk1.>=1).*(H_C.*exp(alpha_1.*(wrk1.==1) + alpha_2.*att1 + alpha_3.*black + wage_shock)); //yearly wages too low right now
#else
	H_C = exp(phi_0 + phi_1[1].*Cr.*((stype.==1||stype.==3)) + phi_1[0].*Cr.*((stype.==2||stype.==4)) + phi_3.*BA + phi_4.*L + phi_5.*(L^2));
	/*Wages*/
	wage = (wrk1.==0).*(omega_1 + omega_2.*L) + (wrk1.>=1).*(HC.*exp(alpha_1.*(wrk1.==1) + alpha_2.*att1 + alpha_3.*black + wage_shock));
#endif

	/*Parental Transfers*/
	transfers = chi_0 + chi_1.*att1 + chi_2.*att1.*wealth + chi_3.*(Cr + 12) + chi_4.*age + chi_7.*H_C + chi_8.*black + chi_10.*wrk1;

/*Transition:
1)	When in School: Just the amount you borrow
2) If grownup, depends whether you go into default or not: goes up my mu if in default, otherwise normal repayment
3) If an old worker, it needs to transition to 0. Need to recheck this. 
*/
	if(GROWNUp.v == 0){	
		n_loans = savings.actual[FeasA[][savings.pos]]';
	}
	else if(GROWNUp.v ==1 && OldWorker.v < 10){
		a =	1;
		r2 = 1/(1+r1);
		n = MaxYrsWrk - OldWorker.v; //to get number of periods left to repay loan
		geo_series = (1 - r2^n)/(1-r2);
		sch_repayment = (schloans)/geo_series; //denominator is a geometric series
		n_loans = (asset.actual[asset.v] + wage + transfers .< sch_repayment).*(schloans.*(mu)) + (asset.actual[asset.v] + wage + transfers .> sch_repayment).*(-sch_repayment);	//see if in default or not, choose the correct transition
		}
	else{
		n_loans = -schloans; //so if loans are > 0 when transitioning to old age, it goes to zero. 
		}
	return n_loans; 	    
	}

//**Transition of Credits**//
QualityConstraints::Transit(FeasA){

	if(GROWNUp.v == 0){
		decl ivals_work = FeasA[][work.pos], ivals_attend = FeasA[][attend.pos];
		decl ability_1 = Abil.v;
		decl pi_f = theta_1.*ability_1 + theta_3.*curt + theta_5.*(ivals_work.==0) + (theta_5 + theta_6).*(ivals_work.<=.5) + (theta_5 + theta_6 + theta_7).*(ivals_work.==1); 
		decl prob_fail = 1/(1+exp(pi_f)); 
		return (prob_fail)~(1-prob_fail)~0; //stay the same, up 1, down 1
	}
	else{
		return 1~0~0; //No transition on credits when grownup. 
	}

}
/*One Period Return*/

QualityConstraints::Utility() {

	decl disu, wage, BA = 0, H_C, util, cons, Age = Age0 + curt, tuition, vasset, grants_gen, grants_spec, transfers, saving_1, asset_1;
	decl age = curt + Age0,	net_tuition;
	decl Cr = Credits.v, stype = SchoolType.v, assets = asset.v, epsil = shocks.v, black = Race.v, wealth = Wealth.v, inc = Inc.v, 
	ability = Abil.v, score = Score.v, nsib = Nsib.v, schloans = Sch_loans.actual[Sch_loans.v];	//getting values 
	decl att = aa(attend), wrk = aa(work), stc = aa(schoice), sav = aa(savings);

	/*Getting values for i.i.d. shocks (can clean this up later)*/
	decl wrk_shock = shocks.Grid[0][epsil[0]];
	decl att_shock = shocks.Grid[1][epsil[1]];
 	decl wage_shock = shocks.Grid[2][epsil[2]];
	decl gen_grants_shock = shocks.Grid[3][epsil[3]];
	decl spec_grants_shock = shocks.Grid[4][epsil[4]];

#ifdef RandomHumanCapital

#else
	decl L = (xper.v)/2;
#endif

/*Human capital & Wages*/
#ifdef RandomHumanCapital
	H_C = HC.v;
 /*Wages*/
	wage = (wrk.==0).*(omega_1) + (wrk.>=1).*(H_C.*exp(alpha_1.*(wrk.==1) + alpha_2.*att + alpha_3.*black + wage_shock));
#else
	H_C = exp(phi_0 + phi_1[1].*Cr.*((stype.==1||stype.==3)) + phi_1[0].*Cr.*((stype.==2||stype.==4)) + phi_3.*BA + phi_4.*L + phi_5.*(L^2));
/*Wages*/
	wage = (wrk.==0).*(omega_1 + omega_2.*L) + (wrk.>=1).*(HC.*exp(alpha_1.*(wrk.==1) + alpha_2.*att + alpha_3.*black + wage_shock));
#endif

/*Tuition & Grants*/
tuition = tau_0[stype];	//
grants_gen = tau_1[0] + tau_1[1].*black + tau_1[2].*inc + tau_1[3].*wealth + tau_1[4].*(score.==1) + tau_1[5].*(score.==2) + tau_1[6].*nsib + gen_grants_shock; //miss 4 year
grants_gen = max(grants_gen, 0);  //cannot have negative grants

grants_spec = tau_2[0] + tau_2[1].*black + tau_2[2].*inc + tau_2[3].*wealth + tau_2[4].*(score.==1) + tau_2[5].*(score.==2) + tau_2[6].*nsib + tau_2[7].*((score.==1)&&(stype.==2)) + tau_2[8].*((score.==2)&&(stype.==2)) + tau_2[9].*(stype.==1) + spec_grants_shock;	//missing grant shock
grants_spec = max(grants_spec, 0); //cannot have negative grants

//no one is getting grants right now with these parameter values
net_tuition = (tuition - grants_gen - grants_spec).*att;

/*Parental Transfers*/
transfers = chi_0 + chi_1.*att + chi_2.*att.*wealth + chi_3.*(Cr + 12) + chi_4.*age + chi_7.*H_C + chi_8.*black + chi_10.*wrk;

/*School loan payments*/
decl r2, a, n, geo_series, sch_repayment1, sch_repayment2;

a =	1;
r2 = 1/(1+r1);
n = MaxYrsWrk - OldWorker.v; //to get number of periods left to repay loan
geo_series = (1 - r2^n)/(1-r2);
sch_repayment1 = (schloans)/geo_series; //denominator is a geometric series

	if(GROWNUp.v == 1 && OldWorker.v < 10){
		sch_repayment2 = (wage + transfers .< sch_repayment1).*(0) + (wage + transfers .>= sch_repayment1).*(-sch_repayment1); 	//only have to repay when grownup
	}
	else if(GROWNUp.v == 1 && OldWorker.v == 10){ 
		sch_repayment2 = zeros(rows(aa(attend)),1); //no repayment in old age...not correct yet, when = 10 that should be the last repayment.  
	}
	else{
		sch_repayment2 = zeros(rows(aa(attend)),1);  //don't have to repay while in school 
	}
	
/*Consumption*/
cons = wage + transfers - net_tuition - sch_repayment2 - savings.actual[sav];
cons = (cons.^(1-rho))/(1-rho);

/*disutility of work + disutility of school*/
disu = (att).*(gamma_20 + att_shock) + (wrk.==1).*(gamma_22 + wrk_shock); // Need to work on this - especially shocks to different schools..

/*Total one period utility*/
util = disu + cons;

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
