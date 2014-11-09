#include "QualityConstraints_2.h"

QualityConstraints_2::Replicate(){

decl KW, PD, PS;

Initialize(1.0,Reachable, FALSE, 0);			//For experiment
//SetClock(UncertainLongevity,TMax,0.0);
SetClock(NormalAging,TMax);
SetDelta(0.95);

		Phi = new array[4];
		Phi[0] = new Coefficients("Phi", <.10,.15,.2,.24,.15,.15>, MSchHCLabels);
		Phi[1] = new Coefficients("Phi_1", <.19,.05,.07,.50,.08,.10,.20>, MWrkHCLabels);
        Phi[2] = new Coefficients("Phi_2", <.05,.1,.1,.12,.076,.11>, MSchNCHCLabels);
        Phi[3] = new Coefficients("Phi_3", <.085,.05,.07,.10,.08,.10,.05>, MWrkNCHCLabels);

	/*	Gamma = new array[2];
		Gamma[0] = new Coefficients("Gamma", <0, -36.85, -150.6>, MSchUtilLabels);
		Gamma[1] = new Coefficients("Gamma_1", <-16.32, 0, -2.645, -1.103, 2.164>, MWrkUtilLabels);

		Omega = new array[2];
		Omega[0] = new Coefficients("Omega", <325.2, 51.53>, MinEarnLabels);
		Omega[1] = new Coefficients("Omega_1", <2.9,0,-.0107, .067, 0.0, -0.22,0.0, 0.0, 0.0, 0.0>,MWageLabels);

		Beta = new array[2];
		Beta[0] = new Coefficients("Beta",	<0.0, 0.0, 0.0, 0.0>, MPrTrnsLabels);
		Beta[1] = new Coefficients("Beta_1", <10.8,.1581,.0021,.0033>, MAmTrnsLabels);
		
	*/	
		Gamma = new Coefficients("Gamma", <0, -36.85, -150.6>, MSchUtilLabels);
		Gamma_1 = new Coefficients("Gamma_1", <-16.32, 0, -2.645, -1.103, 2.164>, MWrkUtilLabels);
		Omega = new Coefficients("Omega", <325.2, 51.53>, MinEarnLabels);
	 	Omega_1 = new Coefficients("Omega_1", <2.9,0,-.0107, .067, 0.0, -0.22,0.0, 0.0, 0.0, 0.0>,MWageLabels);
		Theta = new Coefficients("Theta", <.22, .1, .004, -.1, -.2>, MCreditLabels);
   		Beta = new Coefficients("Beta",	<0.0, 0.0, 0.0>, MPrTrnsLabels);
   		Beta_1 = new Coefficients("Beta_1", <10.8,.0021,.0033>, MAmTrnsLabels);
		Tau_1 = new Coefficients("Tau_1", <-6097, 921.6, -34.7, 2234.4, 4366.2, 944.6, 4123.0, 0.0>, MGrantsLabels);

		dinterest = new array[MIntLabels];
		dinterest[iborrow] = new Determined("iborrow", par[iborrow]);
		dinterest[iunsub] = new Determined("iunsub", par[iunsub]);
  
/**Actions**/
	Actions(
		schoice = new ActionVariable("schoice", MSchooltype), //school choice;
		attend = new ActionVariable("attend", MAttendlabel), //attend school
		work = new ActionVariable("work", MWorklabel),
		savings = new ActionVariable("savings", MaxAssets),
		borrow = new ActionVariable("loans", MaxScAssets),
	 	GrowUp = new ActionVariable("GrowUp", MPhaselabel)); //,

	work.actual = <0.0;0.5;1.0>;
	borrow.actual = <0.0; 3.0; 6.0>;
	savings.actual = <0.0; 1.0; 5.0; 10.0; 20.0>;

/**State Variables:**/

//ENDOGENOUS STATES:

	EndogenousStates(
		GROWNUp = new PermanentChoice("GROWNUp", GrowUp),		
		Credits=  new Forget(new RandomUpDown("Credits", MaxCredits, QualityConstraints_2::Cr_Transit),GROWNUp,Forgotten),
		SchoolType = new Forget(new PermanentChoice("SchoolType", schoice),GROWNUp,Forgotten),
		asset = new Asset("asset", MaxAssets, CV(dinterest[iborrow]), QualityConstraints_2::Savings),
		Sch_loans = new Asset("Sch_loans", MaxScAssets, CV(dinterest[iunsub]), QualityConstraints_2::Loans),
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
		Abil = new FixedEffect("abil", 1),
		Race = new FixedEffect("race", 1),
//		Score = new FixedEffect("score", 1), 	//MScorelabel
//		Wealth = new FixedEffect("wealth", 1),	//MWealthlabel
		Inc = new FixedEffect("income", 1), 		//MInclabel
		Nsib = new FixedEffect("nsib", 1)	//sibling in college or not. 
			   );
		auxwage =  new AuxiliaryVariable("wage");
//		auxtransfer = new AuxiliaryVariable("transfers");
		AuxiliaryOutcomes(auxwage);
			   
//	Volume = LOUD;
	CreateSpaces();
	
	decl Emax = new ValueIteration();
//	data = new CollegeData(Emax);
	
	PD = new EmpiricalMoments("data",Emax,<0>);
	PD->TrackingWithLabel(0,UseLabel,Credits,attend);
	PD->TrackingWithLabel(0,NotInData,HC,GrowUp,savings);
	PD->Read("Quality_Moments.dta");
	PD -> Histogram(GROWNUp,TRUE,TRUE);
	Emax -> Solve();
	PD -> Predict(TMax);
	PD->Histogram(Two);
	println("%c",PD.tlabels,PD.flat[0]);
	delete PD;
}

//QualityConstraints_2::AuxiliaryOutcomes(wage)

/** Read in the data.**/
 /*
CollegeData::CollegeData(method) {
	DataSet("Quality",method,FALSE);
//	Observed(UseLabel);
<<<<<<< HEAD
//	AuxiliaryOutcomes(wage, transfers);	 //Need to add parental transfers to Auxiliary
=======
//	AuxiliaryOutcomes(wage);	 //Need to add parental transfers to Auxiliary
>>>>>>> 671a6aa801451629c99ac5c8a80c5ae243aa8261
	IDColumn("ID_97");
	Read("Quality_Constraints.dta",TRUE);	
	}
*/

/*

NEED OBJECTIVE HERE. 


*/
  
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
	 decl phi = CV(Phi[0]), phi_1 = CV(Phi[1]), phi_2 = CV(Phi[2]), phi_3 = CV(Phi[3]);

//     Now RandomUpDown always takes 3 prob.
	if(!GROWNUp.v){
    HC_up = (FeasA[][attend.pos].==1).*(phi[SchHCInt] + phi[SchAbil]*CV(Abil) + phi[SchHCType1]*(SchoolType.v==1) + phi[SchHCType2]*(SchoolType.v==2) + phi[SchHCType3]*(SchoolType.v==3) + phi[SchHCType4]*(SchoolType.v==4));
    HC_nc = (FeasA[][attend.pos].==1).*(phi_2[SchHCNCInt] + phi_2[SchNCAbil]*CV(Abil) + phi_2[SchHCNCType1]*(SchoolType.v==1) + phi_2[SchHCNCType2]*(SchoolType.v==2) + phi_2[SchHCNCType3]*(SchoolType.v==3) + phi_2[SchHCNCType4]*(SchoolType.v==4));;																										   
	}
	else{
    HC_up = phi_1[WrkHCInt] + phi_1[WrkHCPT]*(FeasA[][work.pos].==1)  + phi_1[WrkHCNCFT]*(FeasA[][work.pos].==2);
    HC_nc = phi_3[WrkHCNCInt] + phi_3[WrkHCNCPT]*(FeasA[][work.pos].==1) + phi_3[WrkHCNCFT]*(FeasA[][work.pos].==2);	
	}
    HC_down = 1 - HC_up - HC_nc;
	if (any(HC_down~HC_nc~HC_up .< 0)) oxrunerror("HC probs. invalid");
     return HC_down~HC_nc~HC_up;
}



/**Transition of Credits**/
QualityConstraints_2::Cr_Transit(FeasA){
	decl prob_fail, prob_pass, prob_down;
	decl theta = CV(Theta);

	decl Age = curt + Age0;
	
  	if(!CV(GROWNUp)){
		decl ivals_work = FeasA[][work.pos], ivals_attend = FeasA[][attend.pos]; 
	    prob_pass = ivals_attend .? (theta[CrPassInter] + theta[CrPassAbil]*CV(Abil) + theta[CrPassPT]*(ivals_work.==.5) + theta[CrPassFT]*(ivals_work.==1)) .: 0;
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
	decl stype = CV(SchoolType), schloans = Sch_loans.actual[CV(Sch_loans)];	//getting values 
	decl att1 = FeasA[][attend.pos], wrk1 = FeasA[][work.pos], sav1 = FeasA[][borrow.pos];
	decl wage_shock = wagesig*AV(wageoffer);

	decl omega = CV(Omega), omega_1 = CV(Omega_1), beta = CV(Beta), beta_1 = CV(Beta_1);

	//	enum{AmTrnsInt, AmTrnsParInc, AmTrnsParW, AmTrnsAtt, MAmTrnsLabels}	//Amount Parental Transfer - beta_1

	
	 /*Wages*/
	wage = (wrk1.==0) .? ((omega[MinEarnInt]) + (omega[MinEarnHC])*CV(HC))*52
	                  .: (CV(HC)*exp(omega_1[WageInt] + omega_1[WagePT]*(wrk1.==1) + omega_1[WageAtt]*att1 + omega_1[WageHC]*CV(HC) + wage_shock))*hours*weeks.*AV(wrk1)/2; //yearly wages too high right now 
	/*Parental Transfers*/
	transfers = (curt>=TMax-2) ? 0 : beta_1[AmTrnsInt] + beta_1[AmTrnsAtt]*att1 + beta_1[AmTrnsParInc]*CV(Inc);
	gross = AV(asset) + wage + transfers;

	if(!CV(GROWNUp)){
		/*Tuition & Grants*/
//		decl grants = Tau[GrantsInt] + Tau[GrantsBlack]*Race + tau[GrantsInc]*CV(Inc) + tau[GrantsAbil1]*(CV(Abil==1)) + tau[GrantsAbil2]*CV(Abil==2) + tau[GrantsNsib]*CV(Nsib) + tau[GrantsAb1St2]*(CV(Abil==1)&CV(stype==1)) + tau[GrantsAb2St1]*(CV(Abil==2)&CV(stype==1));
		decl grants = 5;
		net_tuition = (tau_0[stype] - grants)*att1;
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
	return savings.actual[FeasA[][savings.pos]];
	}

QualityConstraints_2::Event() {
	return (curt >= TMax-2);
	}
	
	QualityConstraints_2::Utility() {

	decl gamma = CV(Gamma);
	decl gamma_1 = CV(Gamma_1);

	if (curt==TMax-1 || curt==0) return zeros(rows(A[Aind]),1);

	decl cons =	/*Consumption*/
		//gross - net_tuition - n_loans - savings.actual[aa(savings)]' + borrow.actual[aa(borrow)]'; //not right?
		//net-savings is state-and action-dependent change in asset holding:
		wage + transfers - net_tuition - n_loans - savings.actual[aa(savings)]' + borrow.actual[aa(borrow)]'; //is this right?

	/*Total one period utility*/
	decl util = cons .<= 0.0 .? -.Inf .:  (cons.^(1-rho))/(1-rho) + aa(attend)*gamma[SchUtilType1] + aa(work)*gamma_1[WrkUtilFullTime];

	return util;
	}

	