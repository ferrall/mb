#include "QualityConstraints_2.h"

QualityConstraints_2::Replicate(){

decl KW, PD, PS, vmat, expbirths, t;

Initialize(1.0,Reachable, TRUE, 0);
SetClock(UncertainLongevity,TMax,0.0);
SetDelta(0.95);

/**Actions**/
	Actions(
		work = new ActionVariable("work", MWorklabel) );

	work.actual = <0.0,0.5,1.0>;

/**State Variables:**/

//ENDOGENOUS STATES:

	EndogenousStates(
 		HC = new RandomUpDown("HC", MaxHC, QualityConstraints_2::HC_trans));
	
	CreateSpaces();
	Volume = NOISY;
	decl Emax = new ValueIteration(0);
//	Emax.Volume = NOISY;
	Emax -> Solve(0,0);
	PD = new PanelPrediction(0);
	PD -> Predict(22);
	PD -> Histogram(HC,TRUE,TRUE);
	delete PD;
}

/**CONSTRAINTS ON CHOICE:**/
QualityConstraints_2::FeasibleActions(const Alpha) {
	
	decl Age = curt + Age0, A;

	A = ones(Alpha);
	
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
		HC_down = 1 - HC_up - HC_nc;

		if(HC.v == 0){
//		println(HC_down~HC_nc~HC_up~HC_down+HC_nc+HC_up);
		return HC_down+HC_nc~HC_up;
		}
		else if(HC.v == MaxHC){
//		println(HC_down~HC_nc~HC_up~HC_down+HC_nc+HC_up);
		return HC_down~HC_nc+HC_up;
		}
		else{
//		println(HC_down~HC_nc~HC_up~HC_down+HC_nc+HC_up);
		return HC_down~HC_nc~HC_up;
		}

//		println(HC_down~HC_nc~HC_up);
//		return HC_down~HC_nc~HC_up;

//	println(FeasA~zeros(rows(FeasA),1));
	}
	else{
	 	return zeros(rows(FeasA),1)~ones(rows(FeasA),1)~zeros(rows(FeasA),1);
	}
}

QualityConstraints_2::Utility() {

	if (curt==TMax-1 || curt==0) return zeros(rows(A[Aind]),1);

	wage = ((omega_1) + (omega_2)*CV(HC))*52.*aa(work);
				  

	decl cons =	wage; /*Consumption*/

	/*Total one period utility*/
	decl util = cons .<= 0.0 .? -.Inf .:  (cons.^(1-rho))/(1-rho) + aa(work)*gamma_22;

	return util;
	}
	