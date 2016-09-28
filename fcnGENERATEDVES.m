function [matCENTER, vecDVEHVSPN, vecDVEHVCRD, vecDVELESWP, vecDVEMCSWP, vecDVETESWP, ...
    vecDVEROLL, vecDVEPITCH, vecDVEYAW, vecDVEAREA, matDVENORM, ...
    matVLST, matDVE, valNELE, matADJE, vecDVESYM, vecDVETIP] = fcnGENERATEDVES2(valPANELS, matGEOM, vecSYM, vecN, vecM)

%   V0 - before fixing spanwise interp
%   V1 - fixed vertical panel (90deg dihedral)
%      - Reprogrammed the DVE interpolation method
%  1.1 - Preallocate the memory for point matrices, do you know how memory is accessed?
%   V2 - Rework the Leading Edge Vector
%      - Caculate the Yaw angle of the DVE by assuming yaw=0 to rotate the xsi vector
%      - Rotate DVE normal vector by local roll, pitch, and yaw using 'glob_star_3D'
%      - Comptue LE Sweep
%      - Project TE to DVE, Rotate adn Comptue TE Sweep
%   V3 - Function overhaul for VAP2.0
%
% Fixed how DVEs matrix is converted from 2D grid to 1D array. 16/01/2016 (Alton)

% INPUT:
%   valPANELS - number of wing panels
%   matGEOM - 2 x 5 x valPANELS matrix, with (x,y,z) coords of edge points, and chord and twist at each edge
%   vecSYM - valPANELS x 1 vector of 0, 1, or 2 which denotes the panels with symmetry
%   vecN - valPANELS x 1 vector of spanwise elements per DVE
%   vecM - valPANELS x 1 vector of chordwise elements per DVE

% OUTPUT: (ALL OUTPUT ANGLES ARE IN RADIAN)
%   matCENTER - valNELE x 3 matrix of (x,y,z) locations of DVE control points
%   vecDVEHVSPN - valNELE x 1 vector of DVE half spans
%   vecDVEHVCRD - valNELE x 1 vector of DVE half chords
%   vecDVELESWP - valNELE x 1 vector of DVE leading edge sweep (radians)
%   vecDVEMCSWP - valNELE x 1 vector of DVE mid-chord sweep (radians)
%   vecDVETESWP - valNELE x 1 vector of DVE trailing-edge sweep (radians)
%   vecDVEROLL - valNELE x 1 vector of DVE roll angles (about x-axis) (radians)
%   vecDVEPITCH - valNELE x 1 vector of DVE pitch angles (about y-axis) (radians)
%   vecDVEYAW - valNELE x 1 vector of DVE yaw angles (about z-axis) (radians)
%   vecDVEAREA - valNELE x 1 vector of DVE area
%   vecDVENORM -  valNELE x 3 matrix of DVE normal vectors
%   matVLST - ? x 3 list of unique vertices, columns are (x,y,z) values
%   valNELE - total number of DVEs
%   matDVE - matrix of which DVE uses which vertices from the above list
%   matADJE - matADJE - ? x 3 adjacency matrix, where columns are: DVE | local edge | adjacent DVE
%   vecDVESYM - valNELE x 1 vector of which DVEs have symmetry on which edge (0 for no symmetry, 2 for local edge 2, 4 for local edge 4)
%   vecDVETIP - valNELE x 1 vector of which DVEs are at the wingtip. Similar format to vecDVESYM

% FUNCTIONS USED:
%   fcnPANELCORNERS
%   fcnPANEL2DVE
%   fcnGLOBSTAR


valNELE = sum(vecM.*vecN);


dve2panel   = nan(valNELE,1);

P1          = nan(valNELE,3);
P12         = nan(valNELE,3);
P2          = nan(valNELE,3);
P3          = nan(valNELE,3);
P4          = nan(valNELE,3);
vecDVESYM   = zeros(valNELE,1);
vecDVETIP   = zeros(valNELE,1);




vecEnd      = cumsum(vecN.*vecM);



for i = 1:valPANELS;
    
    rchord = matGEOM(1,4,i); repsilon = deg2rad(matGEOM(1,5,i));
    tchord = matGEOM(2,4,i); tepsilon = deg2rad(matGEOM(2,5,i));
    rLE = matGEOM(1,1:3,i);
    tLE = matGEOM(2,1:3,i);
    
    % Read panel corners
    % For DVE generation. Twist angle is handled along with dihedral angle
    panel4corners = reshape(fcnPANELCORNERS(rLE,tLE,rchord,tchord,repsilon,tepsilon),3,4)';
    
    % fcnPANEL2DVE takes four corners of a panel and outputs vertices of non-planer DVEs
    [ CP, LE_Left, LE_Mid, LE_Right, TE_Left, TE_Right ] = fcnPANEL2DVE( panel4corners, i, vecN, vecM );
    
    % Imaginary Wing for panel adjacencies. Twist of the panels are ignored
    % to ensure no gaps between panels on same wing.
    impanel4corners = reshape(fcnPANELCORNERS(rLE,tLE,rchord,tchord,0,0),3,4)';
    % fcnPANEL2DVE takes four corners of a panel and outputs vertices of non-planer DVEs
    [ ~, imLEL, ~, imLER, imTEL, imTER ] = fcnPANEL2DVE( impanel4corners, i, vecN, vecM );
    
    % WRITE RESULTS
    count = vecN(i)*vecM(i);
    idxStart = vecEnd(i)-count+1;
    idxEnd = vecEnd(i);
    
    

    dve2panel(idxStart:idxEnd,:) = [repmat(i,count,1)];
    

    % Write DVE CENTER POINT Coordinates
    matCENTER(idxStart:idxEnd,:) = reshape(permute(CP, [2 1 3]),count,3);%reshape(CP(:),count,3);

    % Write non-planer DVE coordinates
    P1(idxStart:idxEnd,:) = reshape(permute(LE_Left, [2 1 3]),count,3);
    P12(idxStart:idxEnd,:) = reshape(permute(LE_Mid, [2 1 3]),count,3);
    P2(idxStart:idxEnd,:) = reshape(permute(LE_Right, [2 1 3]),count,3);
    P3(idxStart:idxEnd,:) = reshape(permute(TE_Right, [2 1 3]),count,3);
    P4(idxStart:idxEnd,:) = reshape(permute(TE_Left, [2 1 3]),count,3);

    % Write Imeragary Wings
    imP1(idxStart:idxEnd,:) = reshape(permute(imLEL, [2 1 3]),count,3);
    imP2(idxStart:idxEnd,:) = reshape(permute(imLER, [2 1 3]),count,3);
    imP3(idxStart:idxEnd,:) = reshape(permute(imTER, [2 1 3]),count,3);
    imP4(idxStart:idxEnd,:) = reshape(permute(imTEL, [2 1 3]),count,3);
    
    clear LE_Left LE_Mid LE_Right TE_Right TE_Left ...
        imLEL imLER imTER imTEL ...
        idxStart idxEnd count
end



% Create eta vector for full leading edge
% Non-normalized
% (old method) LE_vec = LE_Right - LE_Left;
leVec = P2-P1;

% Create half chord xsi vector
% Non-normalized
% (old method) xsi_vec = LE_Mid - CP;
xsiVec = P12-matCENTER;

tempM = cross(leVec, xsiVec, 2);
tempM_length = repmat(((tempM(:,1).^2+tempM(:,2).^2+tempM(:,3).^2).^0.5),1,3);
matDVENORM = tempM./tempM_length;



% Roll in Degrees -arctan ( Y component / Z component of DVC normal vector)
% atan2d is used here
% roll(nu) right wing up positive
% (old method) nu = -atan2(DVE_norm(:,:,2),DVE_norm(:,:,3));
vecDVEROLL = -atan2(matDVENORM(:,2),matDVENORM(:,3));


% Pitch in Degrees
% arcsin ( X component of DVE normal vector )
% (old method) epsilon = asin(DVE_norm(:,:,1));
vecDVEPITCH = asin(matDVENORM(:,1));


% Yaw in Degrees
% xsi in local with roll picth, yaw set to zero.. but WHY?
% (old method) xsi_local = fcnGLOBSTAR3D( xsi_vec,nu,epsilon,zeros(vecM(i),vecN(i)) );
xsiLocal = fcnGLOBSTAR(xsiVec,vecDVEROLL,vecDVEPITCH,zeros(valNELE,1));
% % Magnitude of half chord vector
% (old method) xsi = (xsi_local(:,:,1).^2+xsi_local(:,:,2).^2+xsi_local(:,:,3).^2).^0.5;
vecDVEHVCRD = (xsiLocal(:,1).^2+xsiLocal(:,2).^2+xsiLocal(:,3).^2).^0.5;
% (old method) psi = atan(xsi_local(:,:,2)./xsi_local(:,:,1));
vecDVEYAW = atan(xsiLocal(:,2)./xsiLocal(:,1));
% 
% % Find eta. bring non-normalized LE_vec to local and half the Y component
% (old method) LE_vec_local = fcnGLOBSTAR3D( LE_vec,nu,epsilon,psi);
leVecLocal = fcnGLOBSTAR(leVec,vecDVEROLL,vecDVEPITCH,vecDVEYAW);
% (old method) eta = LE_vec_local(:,:,2)./2;
vecDVEHVSPN = leVecLocal(:,2)./2;
% 
% % Find Leading Edge Sweep
% % arctan(LE X local component/ LE Y local component)
% (old method) phi_LE = atan(LE_vec_local(:,:,1)./LE_vec_local(:,:,2));
vecDVELESWP = atan(leVecLocal(:,1)./leVecLocal(:,2));
% Find Trailing Edge Sweep
% Project TE Points onto DVE plane
% (TE_Left / TE_Right) (CP)                   (DVE_norm)
% q(x,y,z) TE point | p(a,b,c) Control Point | n(d,e,f) DVE normal
% q_proj = q - dot(q-p,n)*n
% (old method) TE_Left_proj = TE_Left-repmat(dot(TE_Left-CP,DVE_norm,3),1,1,3).*DVE_norm;
teLeftProj = P4 - repmat(dot(P4-matCENTER,matDVENORM,2),1,3).*matDVENORM;
% (old method) TE_Right_proj = TE_Right-repmat(dot(TE_Right-CP,DVE_norm,3),1,1,3).*DVE_norm;
teRightProj = P3 - repmat(dot(P3-matCENTER,matDVENORM,2),1,3).*matDVENORM;
% (old method) TE_vec_proj = TE_Right_proj - TE_Left_proj;
teVecProj = teRightProj-teLeftProj;

% Rotate the Projected TE on DVE to local reference frame
% arctan(Projected TE local X component/Projected TE local Y component)
% (old method) TE_vec_proj_local = fcnGLOBSTAR3D( TE_vec_proj,nu,epsilon,psi );
teVecProjLocal = fcnGLOBSTAR(teVecProj,vecDVEROLL,vecDVEPITCH,vecDVEYAW);
% (old method) phi_TE = atan(TE_vec_proj_local(:,:,1)./TE_vec_proj_local(:,:,2));
vecDVETESWP = atan(teVecProjLocal(:,1)./teVecProjLocal(:,2));


% Compute DVE Mid-chord Sweep
% Average of LE and TE Sweep
% (old method) phi_MID = (phi_LE+phi_TE)./2;
vecDVEMCSWP = (vecDVELESWP+vecDVETESWP)./2;

% Calculating Area
% (old method) Area = eta.*xsi.*4;
vecDVEAREA = vecDVEHVCRD.*vecDVEHVSPN.*4;






% output matDVE, index list which describes the DVE coordinates along with
% vertices location in matVLST
% (old method) verticeList = [LECoordL;LECoordR;TECoordR;TECoordL];
verticeList = [P1;P2;teRightProj;teLeftProj];
[matVLST,~,matDVE] = unique(verticeList,'rows');
matDVE = reshape(matDVE,valNELE,4);






% Solve ADJT DVE
% Grab the non-planer vertex list to avoid the gaps between DVEs
nonplanerVLST = [imP1;imP2;imP3;imP4];
[~,~,matNPVIDX] = unique(nonplanerVLST,'rows');
matNPVIDX = reshape(matNPVIDX,valNELE,4);
temp = sort([matNPVIDX(:,[1,2]);matNPVIDX(:,[2,3]);matNPVIDX(:,[3,4]);matNPVIDX(:,[4,1])],2); %sort to ensure the edge is align to same direction
[~,~,j] = unique(temp,'rows','stable');
EIDX = reshape(j,valNELE,4);
clear temp ans j
%row: DVE# | Local Edge # | Glob. edge#
j = [repmat([1:valNELE]',4,1),reshape(repmat(1:4,valNELE,1),valNELE*4,1),reshape(EIDX,valNELE*4,1)];
[j1,~] = histc(j(:,3),unique(j(:,3)));
j = [j,j1(j(:,3))-1];
%Currently the procedure was done in two for loops. May be modified in
%later days if performance improvement is required.
matADJE = nan(sum(j(:,4)),3);
k = j(j(:,4)~=0,:);
c = 0;

idx1 = (j(:,4)==0&(j(:,2)==2|j(:,2)==4));
dveedge2panel = repmat(dve2panel,4,1);


findTIPSYM = [j(idx1,:),dveedge2panel(idx1,:)];
tempTIP = nan(length(findTIPSYM(:,1)),1);
% If the panel has vecSYM = 1, those panels' local edge 4 has symmetry
panelidx = find(vecSYM==1);
symidx = (findTIPSYM(:,2)==4 & ismember(findTIPSYM(:,5),panelidx));
tempTIP(symidx) = 1;
dveidx = findTIPSYM(symidx,1);
vecDVESYM(dveidx) = 4;

% If the panel has vecSYM = 2, those panels' local edge 2 has symmetry
panelidx = find(vecSYM==2);
symidx = (findTIPSYM(:,2)==2 & ismember(findTIPSYM(:,5),panelidx));
tempTIP(symidx) = 1;
dveidx = findTIPSYM(symidx,1);
vecDVESYM(dveidx) = 2;

% If the edge is not touching another dve nor symmetry edge, 
% Define it as wing tip
tipidx = isnan(tempTIP);
dveidx=  findTIPSYM(tipidx,1);
vecDVETIP(dveidx) = findTIPSYM(tipidx,2);



for i = 1:length(k(:,1))
    for i2 = 1:k(i,4)
        c = c+1;
        currentdve = k(i,1);
        currentlocaledge = k(i,2);
        currentedge = k(i,3);
        
        dvefulllist = j(j(:,3)==currentedge,1);
        dvefilterlist = dvefulllist(dvefulllist~=currentdve);
        matADJE(c,:) = [currentdve currentlocaledge dvefilterlist(i2)];
    end
end
%sort matADJE by dve#
[~,B] = sort(matADJE(:,1));
matADJE = matADJE(B,:);



end







