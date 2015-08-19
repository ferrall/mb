#include "QualityConstraints_3.h"

QualityConstraints_3::Replicate(){

decl KW, PD, PS;

//Initialize(QualityConstraints_3::Reachable, TRUE);  //For 7.1 version
Initialize(new QualityConstraints_3(), TRUE);
SetClock(UncertainLongevity,TMax,0.0);
//SetClock(NormalAging,TMax);
SetDelta(0.95);

		Phi = new array[4];
		Phi[0] = new Coefficients("Phi", <.20,.15,.02,.124,.15,.15>, MSchHCLabels);	//still problems with this?
		Phi[1] = new Coefficients("Phi_1", <.15,.05,.07,.50,.08,.10,.20>, MWrkHCLabels);
        Phi[2] = new Coefficients("Phi_2", <.05,.1,.1,.12,.076,.11>, MSchNCHCLabels);
        Phi[3] = new Coefficients("Phi_3", <.085,.05,.07,.10,.08,.10,.05>, MWrkNCHCLabels);

		Gamma = new array[2];
		Gamma[0] = new Coefficients("Gamma", <0, -36.85, -150.6>, MSchUtilLabels);
		Gamma[1] = new Coefficients("Gamma_1", <-16.32, 0, -2.645, -1.103, 2.164>, MWrkUtilLabels);

		Omega = new array[2];
		Omega[0] = new Coefficients("Omega", <15.2, 11.53>, MinEarnLabels);
		Omega[1] = new Coefficients("Omega_1", <10.9,0,-.1107, .167, 0.0, -1.22,0.0, 0.0, 0.0, 0.0>,MWageLabels);

		Beta = new array[2];
		Beta[0] = new Coefficients("Beta",	<0.0, 0.0, 0.0, 0.0>, MPrTrnsLabels);
		Beta[1] = new Coefficients("Beta_1", <10.8,.1581,.0021,.0033>, MAmTrnsLabels);

		Tau = new Coefficients("Tau", <-6097, 921.6, -34.7, 2234.4, 4366.2, 944.6, 4123.0, 0.0>, MGrantsLabels);
		Theta = new Coefficients("Theta", <.22, .1, .004, -.1, -.2>, MCreditLabels);

		dinterest = new array[MIntLabels];
		dinterest[iborrow] = new Determined("iborrow", par[iborrow]);
		dinterest[iunsub] = new Determined("iunsub", par[iunsub]);

		dtuition = new array[MTuitionLabels];
		dtuition[TuitionSch1] = new Determined("T_Pri_Elite", tau_0[TuitionSch1]);
		dtuition[TuitionSch2] = new Determined("T_Pub_Elite", tau_0[TuitionSch2]);
		dtuition[TuitionSch3] = new Determined("T_Pri", tau_0[TuitionSch3]);
		dtuition[TuitionSch4] = new Determined("T_Pub", tau_0[TuitionSch4]);
  
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
		Credits=  new Forget(new RandomUpDown("Credits", MaxCredits, Cr_Transit),GROWNUp,0),
		SchoolType = new Forget(new PermanentChoice("SchoolType", schoice),GROWNUp,0),
		asset = new Asset("asset", MaxAssets, CV(dinterest[iborrow]), Savings),
		Sch_loans = new Asset("Sch_loans", MaxScAssets, CV(dinterest[iunsub]), Loans),
		HC = new Freeze(new RandomUpDown("HC", MaxHC, HC_trans,FALSE), Event())
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
		Inc = new FixedEffect("income", 1), 		//MInclabel
		Nsib = new FixedEffect("nsib", 1)	//sibling in college or not. 
			   );
			   
//		auxwage =  new AuxiliaryVariable("wage");
//		auxtransfer = new AuxiliaryVariable("transfers");
//		AuxiliaryOutcomes(auxwage);
			   
//	Volume = LOUD;
	CreateSpaces(LogitKernel);
	
	decl Emax = new ValueIteration();

     PD = new EmpiricalMoments("data",Emax,UseLabel);
	 PD.Volume = QUIET;
	 PD->TrackingWithLabel(AllFixed,UseLabel,Credits,attend,Sch_loans, work);
     PD->TrackingWithLabel(AllFixed,NotInData,HC,GROWNUp,savings);
     PD->Read("Quality_Moments_New.dta");	//These are overall moments, no demo-specific
//	 Emax -> Solve();
//	 PD -> Predict(TMax); //Edited July 2015
//	 PD -> Predict();
//	 PD -> Histogram(Two);
//	 println("%c",PD.tlabels,PD.flat[0]);
	 Emax.RunSafe = FALSE;	  //Edited July 2015
//	 Explore(PD, 0, 0, Omega, Gamma);

 	 myobj = new PanelBB("myobj", PD, Omega, Gamma, Phi);
	 myobj.Volume = LOUD;
	 GMM = new NelderMead(myobj);
	 GMM.Volume = LOUD;
	 GMM -> Iterate(0);
//	 Encode();
	 delete PD, myobj, GMM;
}

/**CONSTRAINTS ON CHOICE:**/
QualityConstraints_3::FeasibleActions(const Alpha) {
	
	decl Age = I::t + Age0, A;

	if (I::t == 0) return (!Alpha[][attend.pos] .* !Alpha[][work.pos] .* !Alpha[][savings.pos].* !Alpha[][borrow.pos])
			.*!(Alpha[][GrowUp.pos].*Alpha[][schoice.pos]).*(1 - (!Alpha[][GrowUp.pos].*!Alpha[][schoice.pos]));
	
	A = (Alpha[][schoice.pos].==0);

	if (I::t >= MaxTAtt){
	A .*= (Alpha[][GrowUp.pos].==Older);  	/*Must grow up at certain age*/
	}
	
	if (CV(GROWNUp) == 1) {
		A .*= (Alpha[][GrowUp.pos].==Older); 
		A .*= (Alpha[][attend.pos].==NoAttend);  	/*rule out school attendance when grownup = 0*/
		A .*= (Alpha[][borrow.pos].==0); /*would need to change if change grid points*/
		}
	else{
		A .*= (Alpha[][savings.pos].==0);	 /*Would need to change if i change the grid points for savings*/
		A .*= 1 - (!Alpha[][attend.pos]).*!(!Alpha[][borrow.pos]); //can only borrow if going to school

			if(I::t == 10) A.*=(Alpha[][GrowUp.pos].==Older); //If you have not grown up after 10 years in school, must grow grow up.
		}
			//For some reason this changes TMax-2 to have to be 1. 
//	if(I::t == TMax-1){
//		A .*= (Alpha[][work.pos].==FullWork); /*Must work FT in stationary phase*/
//	}
	
	if(I::t == TMax-2){
		A .*= (Alpha[][work.pos].==FullWork); /*Must work FT in stationary phase*/
//		A .*= (Alpha[][work.pos].==2);
	}
	
	return A;
	}

QualityConstraints_3::Reachable() {


	//Initial Choice Phase
	if (I::t == 0) {
			if (CV(GROWNUp) || !(CV(Sch_loans)==0) || !(CV(asset)==0) || !(CV(Credits)==0) || !(CV(SchoolType)==0) ) return 0;
			}
			//cant be grown up in initial decision
			//can't be mature worker in inital decision
			//can't start off with student loans
			//Can't have assets in initial decision
			
			
	//Working Phase		
	if ( (I::t > MaxTAtt || CV(GROWNUp) ) && ( CV(SchoolType)!=Forgotten || CV(Credits)!=Forgotten ) ) return 0;

	//Do I need another one that says GROWNUp == 0 not feasible here? Shouldn't that be redundant? 

	//Mature Phase
	if (I::t == TMax-2) {
		if (CV(Sch_loans)||CV(Credits)||CV(SchoolType)||!CV(GROWNUp)) return 0; //forget student loans once older worker, the other two already forgotten.
			}

	if(I::t >= TMax-1) {
	  	if(CV(Sch_loans)||CV(Credits)||CV(SchoolType)||CV(GROWNUp)||CV(HC)) return 0;
	}


	if (I::t >= TMax-1) return 0;  //never die -> shouldn't this give 0's for HC and GROWNUP?!

//	if (I::t == TMax) return 0;  //never die
	
	return new QualityConstraints_3();
	}

 
 QualityConstraints_3::HC_trans(FeasA) {

 		decl HC = 0;
 		decl phi = CV(Phi[0]), phi_1 = CV(Phi[1]), phi_2 = CV(Phi[2]), phi_3 = CV(Phi[3]);

		if(!GROWNUp.v){
			HC ~=
				(phi_2[SchHCNCInt] + phi_2[SchNCAbil]*CV(Abil) +
				(FeasA[][attend.pos].==1).*phi_2[SchHCNCType1]*(SchoolType.v==1) +
				(FeasA[][attend.pos].==1).*phi_2[SchHCNCType2]*(SchoolType.v==2) +
				(FeasA[][attend.pos].==1).*phi_2[SchHCNCType3]*(SchoolType.v==3) +
				(FeasA[][attend.pos].==1).*phi_2[SchHCNCType4]*(SchoolType.v==4))


				~ (phi[SchHCInt] + phi[SchAbil]*CV(Abil) +
				(FeasA[][attend.pos].==1).*phi[SchHCType1]*(SchoolType.v==1) +
				(FeasA[][attend.pos].==1).*phi[SchHCType2]*(SchoolType.v==2) +
				(FeasA[][attend.pos].==1).*phi[SchHCType3]*(SchoolType.v==3) +
				(FeasA[][attend.pos].==1).*phi[SchHCType4]*(SchoolType.v==4));
			}
		else{
			HC ~=
				(phi_3[WrkHCNCInt] + phi_3[WrkHCNCPT]*(FeasA[][work.pos].==1) +
				phi_3[WrkHCNCFT]*(FeasA[][work.pos].==2))
				
				~(phi_1[WrkHCInt] + phi_1[WrkHCPT]*(FeasA[][work.pos].==1)  +
				phi_1[WrkHCNCFT]*(FeasA[][work.pos].==2));
				}
				
		HC = exp(HC);

		return HC ./ sumr(HC);
}



/**Transition of Credits**/
QualityConstraints_3::Cr_Transit(FeasA){
	decl prob_fail, prob_pass, prob_p, prob_down;
	decl theta = CV(Theta);

	decl Age = I::t + Age0;
	
  	if(!CV(GROWNUp)){
		decl ivals_work = FeasA[][work.pos], ivals_attend = FeasA[][attend.pos];
		
	    prob_pass = ivals_attend .? (theta[CrPassInter] + theta[CrPassAbil]*CV(Abil) + theta[CrPassPT]*(ivals_work.==.5) + theta[CrPassFT]*(ivals_work.==1)) .: 0;
		prob_p = ivals_attend .? (exp(prob_pass)./(1+exp(prob_pass))) .: 0;
		 }
	else{
		prob_p = 0;
	}
	prob_down = 0;
	prob_fail = 1 - prob_p;

	return prob_down ~ prob_fail ~ prob_p;
}

QualityConstraints_3::Loans(FeasA){
	decl th = Settheta(I::all[tracking]);
	return th->Budget(FeasA);	
	}
	
//Net savings for school loans
QualityConstraints_3::Budget(FeasA) {
	gross = net_tuition = n_loans = 0.0;
	if (I::t==0) return 0;
	
	decl BA = 0, Age = Age0 + I::t, sch_repayment;
	decl stype = CV(SchoolType);
	decl schloans = Sch_loans.actual[CV(Sch_loans)];	//getting values 
	decl att1 = FeasA[][attend.pos], wrk1 = FeasA[][work.pos], sav1 = FeasA[][borrow.pos];
	decl wage_shock = wagesig*AV(wageoffer);
	decl tau = CV(Tau);
	decl omega_0 = CV(Omega[0]), omega_1 = CV(Omega[1]), beta = CV(Beta[0]), beta_1 = CV(Beta[1]);

	 /*Wages*/
	if(I::t < TMax-2){
//	if(I::t < TMax-1){
		wage = (wrk1.==0) .? ((omega_0[MinEarnInt]) + (omega_0[MinEarnHC])*CV(HC))*52
	                  .: (CV(HC)*exp(omega_1[WageInt] + omega_1[WagePT]*(wrk1.==1) + omega_1[WageAtt]*att1 + omega_1[WageHC]*CV(HC) + wage_shock))*hours*weeks.*AV(wrk1)/2;
	}
	else{		  //Updated June (2015) to resolve issue of wages being 0 in stationary phase when working full-time (forced to) and 0 HC. 
		 wage = max(omega_0[MinEarnInt], CV(HC)*exp(omega_1[WageInt] + omega_1[WageHC]*CV(HC) + wage_shock))*hours*weeks.*AV(wrk1)/2;
		}
	
	/*Parental Transfers*/
	transfers = (I::t>=TMax-2) ? 0 : beta_1[AmTrnsInt] + beta_1[AmTrnsAtt]*att1 + beta_1[AmTrnsParInc]*CV(Inc);
//	transfers = (I::t>=TMax-1) ? 0 : beta_1[AmTrnsInt] + beta_1[AmTrnsAtt]*att1 + beta_1[AmTrnsParInc]*CV(Inc);
	gross = AV(asset) + wage + transfers;

	if(!CV(GROWNUp)){
		/*Tuition & Grants*/
		decl grants = tau[GrantsInt] + tau[GrantsBlack]*CV(Race) + tau[GrantsInc]*CV(Inc) + tau[GrantsAbil1]*(Abil.v==1) + tau[GrantsAbil2]*(Abil.v==2) + tau[GrantsNsib]*CV(Nsib) + tau[GrantsAb1St2]*((Abil.v==1)&&(SchoolType.v==1)) + tau[GrantsAb2St1]*((Abil.v==2)&&(SchoolType.v==1));
		net_tuition = (CV(tau_0[stype]) - grants)*att1;
		n_loans = 0.0; //no payment while in school
		return borrow.actual[FeasA[][borrow.pos]];
		}
	else {
		net_tuition = 0.0;
		if (I::t>=TMax-3) return -schloans; //so if loans are > 0 when transitioning to old age, it goes to zero.
	//			if (I::t>=TMax-2) return -schloans;
		sch_repayment = (schloans)/(1 - (1/(1+r1))^(TMax-2 - I::t))/(1-(1/(1+r1))); //denominator is a geometric series
		n_loans = (gross .< sch_repayment) .? mu*schloans .: -sch_repayment;	//see if in default or not, choose the correct transition
		return n_loans;
		}
	}

 
QualityConstraints_3::Savings(FeasA){
	return savings.actual[FeasA[][savings.pos]];
	}

QualityConstraints_3::Event() {
	return (I::t >= TMax-2);
	}

//QualityConstraints_3::Event() {
//	return (I::t >= TMax-1);
//	}

	
QualityConstraints_3::Utility() {
	decl gamma = CV(Gamma[0]);
	decl gamma_1 = CV(Gamma[1]);

	if (I::t==TMax-1 || I::t==0) return zeros(rows(A[Aind]),1);
//	if (I::t==TMax || I::t==0) return zeros(rows(A[Aind]),1);

	//	println("time",I::t);//~transfers~net_tuition~n_loans~ savings.actual[aa(savings)]');
	//	println("transfers", transfers);
	//	println("loans", n_loans);
	//	println("net_tuition", net_tuition);
	//	println("wage",wage);

	decl cons =	/*Consumption*/
		//gross - net_tuition - n_loans - savings.actual[aa(savings)]' + borrow.actual[aa(borrow)]'; //not right?
		//net-savings is state-and action-dependent change in asset holding:

		wage + transfers - net_tuition - n_loans - savings.actual[aa(savings)]' + borrow.actual[aa(borrow)]'; //is this right?
	/*Total one period utility*/
	decl util = cons .<= 0.0 .? -.Inf .:  (cons.^(1-rho))/(1-rho) + aa(attend)*gamma[SchUtilType1] + aa(work)*gamma_1[WrkUtilFullTime];
	
	return util;
	}