#import "DDP"
#import "FiveO"

struct QualityConstraints_2 : ExtremeValue	{	 //ExpostSmoothing just copied from KW

	decl InSubSample;  //sample
	
		
	//**Labels for school choices. @name Choices **/
	  enum{Noschool, ElitePrivate, Private, ElitePublic, Public, MSchooltype}

	  enum{Forgotten}

	//**Labels for GrowUp**//
	  
	//**Labels for attendance choices. @name Choices **/
	  enum{NoAttend, Attend, MAttendlabel}

	//**Labels for work intensity. @name Choices **/
	   enum{NoWork, PartWork, FullWork, MWorklabel}

	//**Labels for Race**//
	  enum{Black, Other, MRacelabel}

	//**Labels for Ability **//
	  enum{LowAbil, MedAbil, HighAbil, MAbillabel}

	//**Labels for Testscore **//
	  enum{LowTest, MedTest, HighTest, MScorelabel}

	//**Labels for Wealth Tercile**//
	  enum{LowY, MedY, HighY, MWealthlabel}

	//**Labels for Income Tercile**//
	  enum{LowInc, MedInc, HighInc, MInclabel}

	//**Labels for Phases**//
	  enum{SchAge, WrkAge, MPhaselabel}

	 //**Labels for GrowUp**//
	 enum{Young, Older, MGrowUplabel}

	 enum{gen,spec,Ngrants}	
	
	/** State Space Dimensions. @name Dimens **/
	enum{Age0 = 18, MaxCredits=5, MaxTAtt = 10, MaxAssets = 5, MaxScAssets = 3, MaxYrsWrk = 10, TMax=2+MaxTAtt+MaxYrsWrk,Noffers = 3, MaxHC = 3}

	enum{iborrow, isaving, isub, iunsub, MIntLabels}
	enum{SchUtilType1, SchUtilType2, SchUtilType3, MSchUtilLabels}	  //School Utility - Gamma
	enum{WrkUtilFullTime, WrkUtilType_1, WrkUtilType_2, WrkUtilType_3, WrkUtilAge, MWrkUtilLabels}		//Work Utility - Gamma_1
	enum{CrPassInter, CrPassAbil, CrPassAge, CrPassPT, CrPassFT, MCreditLabels}	 //Credit passing - Theta
	enum{MinEarnInt, MinEarnHC, MinEarnLabels} //minimum earnings - Omega
	enum{WageInt, WageFT, WagePT, WageAbil, WageHC, WageAtt, WageType1, WageType2, WageType3, MWageLabels} 	//wages - Omega_1
	enum{SchHCInt, SchAbil, SchHCType1, SchHCType2, SchHCType3, SchHCType4, MSchHCLabels} //HC School (up) - Phi
	enum{WrkHCInt, WrkHCFT, WrkHCPT, WrkHCSType, WrkHCType1, WrkHCType2, WrkHCType3, MWrkHCLabels} //HC Wrk (up) - Phi_1
	enum{SchHCNCInt, SchNCAbil, SchHCNCType1, SchHCNCType2, SchHCNCType3, SchHCNCType4, MSchNCHCLabels} //HC School (No change) - Phi_3
	enum{WrkHCNCInt, WrkHCNCFT, WrkHCNCPT, WrkHCSNCType, WrkHCNCType1, WrkHCNCType2, WrkHCNCType3, MWrkNCHCLabels} //HC Wrk (No change) - Phi_4
	enum{PrTrnsInt, PrTrnsParInc, PrTrnsParW, PrTrnsAtt, MPrTrnsLabels}	//Prob Parental Transfer - beta
	enum{AmTrnsInt, AmTrnsParInc, AmTrnsParW, AmTrnsAtt, MAmTrnsLabels}	//Amount Parental Transfer - beta_1
//	enum{  ,MShocksLabel}

//Need Grants

	static const decl
	//	leisuresig = 201.3,
	//	attsig = 2599.0,
		wagesig = 1.0,
		
	sig = <498, 0, 6796>, //shock 1: work, shock 2: college attendance, 3: wage

	par = <0.05, 0.05, 0.0, 0.07>,
  

	//Risk aversion
	rho = 2, //literature
	r= .05, //interest rate regular 
	r1 = .07,  //interest rate school loans
	mu = .1, //10% gets added to loans if default
	hours = 30, //equivalent full-time hours.
	weeks = 45, //weeks worked per year

	//Asset lower limit
	mu_0 = .5523,
	mu_1 = .0984,
	mu_2 = -.0011,
	mu_3 = .2507,
	mu_4 = .4159,
	
	//Tuition & Grants
	tau_0 = <0, 27530, 17296, 14435, 10215>,  //tuition
	tau = <-6097, 921.6, -34.7, -4.4, 2234.4, 4366.2, 944.6, 4123.0, 0.0, 0.0, 0.0 ;   //General: Cons, black, income/1000, family assets/1000, SAT_2, SAT_3, Sib, 4 year.
           -12641, 6774.1, -71.6, -5.9, 3747.9, 7352.0, 2958.2, 12169.7, 15130.8, -11764.6, -4281.5>; //Specific: Cons, black, income/1000, assets/1000, SAT_2, SAT_3, Sibs, SAT_2private, SAT_3Private, priv_elite, 2-year

	static decl
											data,
											dinterest,
		/** index attend school**/  		attend,
		/*Unobserved HC**/					HC,
											HC_C,
											Sch_loans,
											BA,										
											GrowUp,
		/** school choice **/   			schoice,
		/**work**/							work,
		/**credits earned**/				Credits,
		/**School type**/				  	SchoolType,
		/**Ability Type**/					Abil,
											Race,
											Inc,
											Nsib,
											Wealth,
											Score,
											savings,
											borrow,
											asset,
											xft,
											GROWNUp,
											gshocks,
											wageoffer,
											leisure,
											xper,											
											auxwage,
											IntRates,
											Gamma,
											Gamma_1,
											Omega,
											Omega_1,
											Phi,
											Phi_1,
											Phi_2,
											Phi_3,
											Beta,
											ind,
											Beta_1,
											xpt;

			decl							gross,
											transfers,
											wage,
											net_tuition,
											n_loans;
 
	static 	Replicate();
	static	Reachable();
			Budget(FeasA);
			Utility();
	static	HC_trans(FeasA);
	static	Cr_Transit(FeasA);
	static  Degree_Status(FeasA);
	static  Savings(FeasA);
	static  Loans(FeasA);
	static	Event();
	 	   	FeasibleActions(const Alpha); 
	}

	struct CollegeData : DataSet {
	CollegeData(method=0);
	}


