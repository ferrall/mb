#import "DDP"

struct QualityConstraints_2 : ExtremeValue	{	 //ExpostSmoothing just copied from KW

	decl InSubSample;
		
	//**Labels for school choices. @name Choices **/
	  enum{Noschool, ElitePrivate, Private, ElitePublic, Public, MSchooltype}

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

	 enum{gen,spec,Ngrants}	
	
	/** State Space Dimensions. @name Dimens **/
	enum{Age0 = 18, MaxXper=5, MaxCredits=5, MaxTAtt = 10, MaxAssets = 5, MaxScAssets = 3, MaxYrsWrk = 10, TMax=2+MaxTAtt+MaxYrsWrk,Noffers = 3, MaxHC = 5}
	
	static const decl
//		leisuresig = 201.3,
//		attsig = 2599.0,
		wagesig = 1.0,
		
	sig = <498; 0; 6796>, //shock 1: work, shock 2: college attendance, 3: wage

	//Risk aversion
	rho = 2, //literature
	r= .05, //interest rate regular 
	r1 = .07,  //interest rate school loans
	mu = .1, //10% gets added to loans if default
	hours = 30, //equivalent full-time hours.
	weeks = 45, //weeks worked per year

	//psychic school costs
	gamma_44_2 = -36.85, //type 2	unobserved heterogeneity in school attendance
	gamma_44_3 = -150.6, //type 3	unobserved heterogeneity in school attendance

	//work preferences

	gamma_20 = <-16.32>,  //prefence for working full-time,
	gamma_21 = <0, -2.645, -1.103>, //preferences for work for type2, type3
	gamma_22 = <4.927>, //prefences for working full-time shifter
	gamma_25 = <2.164, -.6864>, //age and full-time, part-time interactions

	//HC function:
	phi_0 = 2.485, //constant
	phi_1 = <.0145, 0.0168>, //years at 2-year/ 4-year
	phi_3 = .1905, //BA completion
	phi_4 = .0685, //years of experience
	phi_5 = -.0032, //years of experience squared
	phi_6 = .00025,	 //ability (but mine is tercile, his is level)
	phi_7 = -.0709, //type 2
	phi_8 = -.2264,	 //type 3.

	//Asset lower limit
	mu_0 = .5523,
	mu_1 = .0984,
	mu_2 = -.0011,
	mu_3 = .2507,
	mu_4 = .4159,

	//credit passing/failing
//	theta_0 = <-4.00,1.00,-2.04,2.40>, //un observedtype 1, 2, 3, 4
	theta_0 = .5,
	theta_1 = .1,	//GPA (i'll make this ability)
	theta_2 = .0730,	//grade they are in
	theta_3 = .09,	//age
	theta_4 = .00999,	//no credits
	theta_5 = .0697,	 //no work
	theta_6 = -.136,	 //pt work
	theta_7 = -.22,	 //ft work

	//Random HC function
	beta_0 = .19,
	beta_1 = .05,
	beta_2 = .07,
	beta_3 = .50,
	beta_4 = .08,
	beta_5 = .10,
	beta_6 = .20,
	beta_7 = .40,
	//Wage equation function

	//minimum earnings
	omega_1 = 325.2,
	omega_2 = 51.53, //*H in wage function

	alpha_0 = 2.9,
	alpha_1 = -.0107, //part-time work
	alpha_2 = -.4677, //enrolled in school
	alpha_3 = -.1015, //black
	alpha_4 = -.0284, //hispanic
	
	//Transfers
	chi_0 =	10.8,	  //constant
	chi_1 =	.1581,
	chi_2=	.0021,
	chi_3 =	.0033,
	chi_4 =	-.1373,
	chi_5 =	.0036,
	chi_6 =	-.0054,
	chi_7 =	.0366,
	chi_8 =	.0467,
	chi_9 =	-.0347,
	chi_10 = .4932,
	
	//Tuition & Grants
	tau_0 = <0, 27530, 16891, 5090, 10540>,  //tuition
	tau = <-6097, 921.6, -34.7, -4.4, 2234.4, 4366.2, 944.6, 4123.0, 0.0, 0.0, 0.0 ;   //General: Cons, black, income/1000, family assets/1000, SAT_2, SAT_3, Sib, 4 year.
           -12641, 6774.1, -71.6, -5.9, 3747.9, 7352.0, 2958.2, 12169.7, 15130.8, -11764.6, -4281.5>; //Specific: Cons, black, income/1000, assets/1000, SAT_2, SAT_3, Sibs, SAT_2private, SAT_3Private, priv_elite, 2-year
//	tau_1 = <-6097, 921.6, -34.7, -4.4, 2234.4, 4366.2, 944.6, 4123.0>,	 //General: Cons, black, income/1000, family assets/1000, SAT_2, SAT_3, Sib, 4 year.
//	tau_2 = <-12641, 6774.1, -71.6, -5.9, 3747.9, 7352.0, 2958.2, 12169.7, 15130.8, -11764.6, -4281.5>; //Specific: Cons, black, income/1000, assets/1000, SAT_2, SAT_3, Sibs, SAT_2private, SAT_3Private, priv_elite, 2-year
	
	static decl 
		/** index attend school**/  		attend,
		/*Unobserved HC**/					HC,
											HC_C,
											Sch_loans,
											BA,										
											GrowUp,
//											OldWorker,
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
											xpt;

			decl							gross,
											wage,
											transfers,
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
	 	   	FeasibleActions(const Alpha); 
	}

