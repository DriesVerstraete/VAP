function [matUINF,zvel] = fcnFLEXUINF(matCENTER_old, matCENTER, valDELTIME, zvel)

lambda = 0.5;

matUINF = ((matCENTER_old - matCENTER)./valDELTIME);

zvel = lambda.*(matCENTER_old(:,3) - matCENTER(:,3))./valDELTIME + (1-lambda).*zvel;

matUINF(:,3) = zvel;
% matUINF = [(matCENTER_old(:,1) - matCENTER(:,1))./valDELTIME,(matCENTER(:,2) - matCENTER_old(:,2))./valDELTIME,(matCENTER(:,3) - matCENTER_old(:,3))./valDELTIME,];

% matUINF = (-matCENTER_old(:,:,valTIMESTEP-2) + 4*matCENTER_old(:,:,valTIMESTEP-1) - 3*matCENTER)./(2*valDELTIME);

% matUINF(:,3) = 0.01*matUINF(:,3);

end