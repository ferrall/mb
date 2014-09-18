#include "QualityConstraints.h"
#define RandomHumanCapital  //uncomment if want to use unobserved state variable
//#define KWApprox //uncomment if using KW

QualityConstraints::Replicate(){

decl KW, PD, PS, vmat, expbirths, t;

Initialize(1.0,Reachable, TRUE, 0);
SetClock(UncertainLongevity,TMax,0.0);
SetDelta(0.97);

//schoice = 0;

/**Actions**/
	Actions(
		work = new ActionVariable("work", MWorklabel), //work
		attend = new ActionVariable("attend", MAttendlabel), //attend school
	 	GrowUp = new ActionVariable("GrowUp", MPhaselabel),  
		savings = new ActionVariable("savings", MaxAssets),
		borrow = new ActionVariable("loans",3) ,
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

//	SchoolType = 0;

	EndogenousStates(
 		HC = new RandomUpDown("HC", MaxHC, QualityConstraints::HC_trans),				
		Credits= new RandomUpDown("Credits", MaxCredits, QualityConstraints::Transit),
		//	BA = new Deterministic("BA", 1, QualityConstraints::Degree_Status),	 //should this be in a state block with credits..right?
		Sch_loans = new Asset("Sch_loans", MaxScAssets, r1, QualityConstraints::Loans),
		asset = new Asset("asset", MaxAssets, r, QualityConstraints::Savings), 
		GROWNUp = new LaggedAction("GROWNUp", GrowUp),
		SchoolType = new PermanentChoice("SchoolType", schoice)
		);

	asset.actual = <0.0, 1000.0, 5000.0, 20000.0, 50000.0>;
	Sch_loans.actual = <0.0, 1000.0, 5000.0, 20000.0, 50000.0>;
		
#else


	EndogenousStates(
  		xper = new ActionAccumulator("xper", MaxXper, work), //adds 1 for part-time, 2 for full-time, max of 10 years of experience, but this should only increase if in phase 1. 				
		Credits= new RandomUpDown("Credits", MaxCredits, QualityConstraints::Transit),
		//Sch_loans = ActionAccumulator("Sch_Loans", Sch_borrowing),
		assets = new LaggedAction("assets", savings),
		GROWNUp = new ActionTracker("GROWNUp", GrowUp, 1 //), 
//		SchoolType = new PermanentChoice("SchoolType", schoice)
);
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
//	Volume = SILENT;
	KW = new KeaneWolpin(ones(1,10)~constant(0.1,1,A1-10),0);
//	KW.Volume = SILENT;
	KW -> Solve();
#else
	CreateSpaces();
	Volume = NOISY;
	decl Emax = new ValueIteration(0);
//	Emax.Volume = NOISY;
	Emax -> Solve(0,0);
//	DPDebug::outV(TRUE,0);
	PD = new PanelPrediction(0);
	PD -> Predict(50);
	PD -> Histogram(GROWNUp,TRUE,TRUE);
	delete PD;


	DPDebug::outV(TRUE,0);
	PS = new Panel(1,0);
//	PS = Simulate(10,20,0,TRUE);
//		DPDebug::outV(TRUE,&vmat);	   //just printing value function
//		chprob |= reverser(vmat[][sizec(vmat)-1]');
//		ps[row] = new Panel(row,0);	//making new panel
//		ps[row] -> Simulate(10,400,0,TRUE);  //draw from ergodic distn.
		//Simulate ( N , T , ErgOrStateMat , DropTerminal ) -> (Paths, time periods, 0, TRUE)
//		ps[row]->Flat();		
//		data |= selectifr(ps[row].flat,ps[row].flat[][columns(ps[row].flat)-1]);
//		}


#endif

}

/**CONSTRAINTS ON CHOICE:**/
QualityConstraints::FeasibleActions(const Alpha) {
	
	decl Age = curt + Age0, A, B_Limit_Sav, B_Limit_Borrow;

	/*Calculate state-dependent borrowing limit here*/
	B_Limit_Sav =  exp(mu_0 + mu_1*CV(HC) + mu_2*CV(HC)^2 + mu_3*Age + mu_4*(Age > 23));  //too small right now.

	/*Only choice in first period, is which school*/
	if (Age == Age0) return !Alpha[][attend.pos] .* !Alpha[][work.pos] .* !Alpha[][savings.pos] .* !Alpha[][GrowUp.pos]
							.* !Alpha[][borrow.pos];

	/*Do not choose school-type after first period*/
	A = (Alpha[][schoice.pos].==0);

//	A = 1; 

	/*Cannot choose to grow up and attend school*/
	A .*= 1 - (Alpha[][attend.pos]).*(Alpha[][GrowUp.pos]);
// redundant??	A .*= 1 - (Alpha[][borrow.pos].>0).*(Alpha[][saving.pos].>0);

	/*Cannot attend school if school type is 0*/
	if (CV(SchoolType) == 0) A .*= (Alpha[][attend.pos].==0);  //this doesn't decrease total states, just shifts between columns
	
	if (curt > MaxTAtt)  {
		A .*=  (Alpha[][attend.pos].==0);   /*rule out schooling if too old*/
		A .*= (Alpha[][GrowUp.pos].==1);  	/*Must grow up at certain age*/
		}

	/*If already GROWNUP, must choose GrowUp every period*/
	if (CV(GROWNUp) == 1) {
		A .*= (Alpha[][GrowUp.pos].==1); 
		A .*= (Alpha[][attend.pos].==0);  	/*rule out school attendance when grownup = 0*/
		A .*= (Alpha[][borrow.pos].==0);	/*would need to change if change grid points*/
		}
	else
		A .*= Alpha[][savings.pos].==0;	 /*Would need to change if i change the grid points for savings*/

	/*Need to limit feasible savings*/
	//Not taking into account wages etc etc. where should this be done?
//	A.*= 1 - (asset.actual[asset.v] + savings.actual[savings.pos] .< B_Limit_Sav);

	/*Old Age: No work choice, all full-time*/
	if(curt >= TMax-2) A.* (Alpha[][work.pos].==2); //work full-time only

	/*Need to rule out school borrowing while not attending*/
	if(CV(SchoolType) != 0 && CV(GROWNUp) == 0) A.*= 1 - (Alpha[][attend.pos] == 0).*(Alpha[][borrow.pos] != 0);   //need to change if change gridpoints

	return A;
	}  
	 
QualityConstraints::Reachable() {
#ifdef RandomHumanCapital
		decl MaxEarned = curt, Cr = CV(Credits);

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
			//Need to change assets if change grid points
			}
		if (!CV(GROWNUp)) {
		   if (CV(asset) || curt>MaxTAtt) return 0;	 //need to change assets if i change grid points
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
		decl MaxEarned = curt, MaxExp = curt, Cr = CV(Credits), yrs_exp = (xper.v)/2;		
		if (CV(Credits) > curt) return 0; 
		if (yrs_exp > curt) return 0;   		
		return new QualityConstraints();
#endif
}

/*Transition of Random Human Capital*/

#ifdef RandomHumanCapital	//based on school attendance, simple up or down  
QualityConstraints::HC_trans(FeasA) {
	decl HC_up, HC_nc, HC_down;

	if(curt<TMax-2){
		//If not grownup, then HC transition based on learning. Otherwise based on working
		HC_up =	AV(GROWNUp) == 0 ? beta_4*(AV(SchoolType)==1)*(FeasA[][attend.pos].==1) + beta_5*(AV(SchoolType)==2).*(FeasA[][attend.pos].==1)
							+ beta_6*(AV(SchoolType)==3)*(FeasA[][attend.pos].==1) + beta_7*(AV(SchoolType)==4)*(FeasA[][attend.pos].==1)  //Learnings
								 : beta_0 + beta_1*(FeasA[][work.pos].==0) + beta_2*(FeasA[][work.pos].==1); //working

		HC_nc =	AV(GROWNUp) == 0 ? beta_4*(AV(SchoolType)==1)*(FeasA[][attend.pos].==1) + beta_5*(AV(SchoolType)==2).*(FeasA[][attend.pos].==1) //Learning								  
								 : beta_0 + beta_1*(FeasA[][work.pos].==0) + beta_2*(FeasA[][work.pos].==1) + beta_3*(FeasA[][work.pos].==2); //working
		HC_down = 1 - HC_up - HC_nc;
//		println("Human Capital", HC_up~HC_nc~HC_down~FeasA);
		return HC_down~HC_nc~HC_up;
	}
	else{
	 	return 0~1~0;
	}
}
#endif

//Net savings for regular asset
QualityConstraints::Savings(FeasA){
	return savings.actual[FeasA[][savings.pos]]';

//Not taking into account wages etc etc. where should this be done?
//	A.*= 1 - (asset.actual[asset.v] + savings.actual[savings.pos] .< B_Limit_Sav);
	}

QualityConstraints::Loans(FeasA){
	decl th = Settheta(ind[tracking]);
	return th->Budget(FeasA);	
	}
	
//Net savings for school loans
QualityConstraints::Budget(FeasA) {
	gross = net_tuition = n_loans = 0.0;
	if (curt==0) return 0;
	
	decl BA = 0, Age = Age0 + curt, sch_repayment;
	decl stype = CV(SchoolType), score = CV(Score), schloans = Sch_loans.actual[CV(Sch_loans)];	//getting values 
	decl att1 = FeasA[][attend.pos], wrk1 = FeasA[][work.pos], sav1 = FeasA[][borrow.pos];
	decl wage_shock = wagesig*AV(wageoffer);

	 /*Wages*/
	wage = (wrk1.==0) .? ((omega_1) + (omega_2)*CV(HC))*52
	                  .: (CV(HC)*exp(alpha_0+alpha_1*(wrk1.==1) + alpha_2*att1 + alpha_3*CV(Race) + wage_shock))*hours*weeks.*AV(wrk1)/2; //yearly wages too high right now
					  
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
		return borrow.actual[FeasA[][borrow.pos]]';
		}
	else {
		net_tuition = 0.0;
		if (curt>=TMax-3) return -schloans; //so if loans are > 0 when transitioning to old age, it goes to zero. 
		sch_repayment = (schloans)/(1 - (1/(1+r1))^(TMax-2 - curt))/(1-(1/(1+r1))); //denominator is a geometric series
		n_loans = (gross .< sch_repayment) .? mu*schloans .: -sch_repayment;	//see if in default or not, choose the correct transition
		return n_loans;
		}
	}

//**Transition of Credits**//

//need to fix.
QualityConstraints::Transit(FeasA){

	if(CV(GROWNUp) == 0){
		decl ivals_work = FeasA[][work.pos], ivals_attend = FeasA[][attend.pos]; 
		decl pi_f = theta_1*CV(Abil) + theta_3*curt + theta_5*(ivals_work.==0) + (theta_5 + theta_6)*(ivals_work.<=.5) + (theta_5 + theta_6 + theta_7)*(ivals_work.==1);
		println("Credits",pi_f~(1-pi_f)~0);
		return 0~(pi_f)~(1-pi_f);
	}
	else{
		return 0~1~0; //No transition on credits when grownup. 
	}

}
/*One Period Return*/

QualityConstraints::Utility() {

	if (curt==TMax-1 || curt==0) return zeros(rows(A[Aind]),1);

	decl cons =	/*Consumption*/
		//gross - net_tuition - n_loans - savings.actual[aa(savings)]' + borrow.actual[aa(borrow)]'; //not right?
		//net-savings is state-and action-dependent change in asset holding:
		wage + transfers - net_tuition - n_loans - savings.actual[aa(savings)]' + borrow.actual[aa(borrow)]'; //is this right?

	/*Total one period utility*/
	decl util = cons .<= 0.0 .? -.Inf .:  (cons.^(1-rho))/(1-rho) + aa(attend)*gamma_20 + aa(work)*gamma_22;

//after raising wages, problem below is not an issue
//	if (!any(util .!= -.Inf)) {
//		println(cons~AV(asset)~gross~savings.actual[aa(savings)]);
//		}

	return util;
	}
	
/*
Need to add:
1)	Borrowing limits - function of current states - age and human capital?
2) Degree status - needs to be in a state block with credits?
3) different interest rates for borrowing and saving?
4) Need to fix human capital probabilities
*/
