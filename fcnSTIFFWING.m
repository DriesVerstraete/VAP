function [matVLST, matCENTER, matNEWWAKE, matNPNEWWAKE, matNTVLST, matNPVLST, matDEFGLOB, matTWISTGLOB, valUINF, valGUSTTIME, matUINF, flagSTEADY] = fcnSTIFFWING(valALPHA, valBETA, valDELTIME, matVLST,...
    matCENTER, matDVE, vecDVETE, matNTVLST, matNPVLST, vecN, valTIMESTEP, vecCL, valWEIGHT, valAREA, valDENSITY, valUINF, valGUSTTIME, valGUSTL, valGUSTAMP, flagGUSTMODE, valGUSTSTART, flagSTEADY, matUINF)

% This function moves the wing in the freestream direction and calculates
% the new wake elements, asssuming no bending of the wing.

matCENTER_old = matCENTER;

[matVLST, matCENTER, matNEWWAKE, matNPNEWWAKE, matNTVLST, matNPVLST, valUINF] = fcnMOVEWING(valALPHA, valBETA, valDELTIME, matVLST, matCENTER, matDVE, vecDVETE, matNTVLST, matNPVLST, vecCL, valWEIGHT, valAREA, valDENSITY, valTIMESTEP, valUINF, matUINF);

% [matUINF] = fcnFLEXUINF(matCENTER_old, matCENTER, valDELTIME);

if valGUSTTIME > 1 || valTIMESTEP == valGUSTSTART
    
    flagSTEADY = 2;
    
    [matUINF] = fcnGUSTWING(matUINF,valGUSTAMP,valGUSTL,flagGUSTMODE,valDELTIME,valGUSTTIME,valUINF,valALPHA,valBETA);
    valGUSTTIME = valGUSTTIME + 1;
    
end

matDEFGLOB(valTIMESTEP,:) = zeros(1,sum(vecN,1)+5);

matTWISTGLOB(valTIMESTEP,:) = zeros(1,sum(vecN,1)+5);

end