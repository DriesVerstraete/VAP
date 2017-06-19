function [out] = fcnOBJFUNCSC()
% clc
% clear


load('Standard Cirrus Input.mat');

flagRELAX = 0;
valMAXTIME = 22;

seqALPHA = 2:12;

vecAIRFOIL = [1 2 4]';
vecN = [6 12 3]';
vecM = [1 1 1]';

% %% Running VAP2
try
[vecCLv, vecCD, vecCDi, vecVINF, vecCLDIST, matXYZDIST, vecAREADIST] = fcnVAP_MAIN(flagRELAX, flagSTEADY, valAREA, valSPAN, valCMAC, valWEIGHT, ...
    seqALPHA, seqBETA, valKINV, valDENSITY, valPANELS, matGEOM, vecSYM, ...
    vecAIRFOIL, vecN, vecM, valVSPANELS, matVSGEOM, valFPANELS, matFGEOM, ...
    valFTURB, valFPWIDTH, valDELTAE, valDELTIME, valMAXTIME, valMINTIME, ...
    valINTERF);
catch
   zp 
end
%% Root bending
% At alpha = 5 degrees
% section cl * y location * density * 0.5 * section area * V_inf^2
% Includes tail, which is a constant offset

idx = find(seqALPHA == 5);
root_bending = sum(vecCLDIST(idx,:).*matXYZDIST(:,2,idx)'.*valDENSITY.*vecAREADIST(idx,:).*(vecVINF(idx)^2));

%% High speed drag coefficient
% Drag coefficient at 51 m/s

highspeed_cd = interp1(vecVINF,vecCD,51,'linear','extrap');

%% Cross-country speed

[LDfit, ~] = fcnCREATEFIT(seqALPHA, vecCLv./vecCD);
[CLfit, ~] = fcnCREATEFIT(seqALPHA, vecCLv);
[CDfit, ~] = fcnCREATEFIT(seqALPHA, vecCD);
[Vinffit, ~] = fcnCREATEFIT(seqALPHA, vecVINF);
[Cdifit, ~] = fcnCREATEFIT(seqALPHA, vecCDi);

range_vxc = 2:0.25:max(seqALPHA);
CL = CLfit(range_vxc);
CD = CDfit(range_vxc);
LD = LDfit(range_vxc);
Vcruise = Vinffit(range_vxc);
wglide = Vcruise.*(CD./CL);
[~, LDindex] = max(LD);

Rthermal = 150;
Rrecip = 1/Rthermal;
WSroh = 2*valWEIGHT/(valAREA*valDENSITY);

k = 1;

% for wmaxth = 2:0.25:8
for wmaxth = 2:3:8
    
    j = 1;
    
    for i = LDindex:size(CL)
        wclimb(j,1) = fcnMAXCLIMB(CL(i), CD(i), Rrecip, wmaxth, WSroh);
        j = j + 1;
    end
    
    [wclimbMAX, indexWC] = max(wclimb);
    
    for i = 1:size(CL)
        V(i,1) = (Vcruise(i)*wclimbMAX)/(wglide(i)+wclimbMAX);
    end
    
    [VxcMAX, cruiseIndex] = max(V);
    invVxcMAX(k,1) = 1/VxcMAX;
    Vxc(k,:) = [wmaxth VxcMAX];
    k = k + 1;
    
end

invVxcMAX_low = invVxcMAX(1,1);
invVxcMAX_med = invVxcMAX(ceil(end/2),1);
invVxcMAX_high = invVxcMAX(end,1);

out = [invVxcMAX_low invVxcMAX_med invVxcMAX_high root_bending highspeed_cd];
end
