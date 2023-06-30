%  Created on: 28/06/2023
%      Author: j-Lago
%
function plot_refresh(hObject, eventdata, handles)

global sombra
global arranjo_gui


% linhas grafico
Lmppt    = LineStyle(':', [1. .6 .3]*1., 2.0, 9);
Lstr1    = LineStyle('-.', [.8 1. 1.]*.8, 2.0, 9);
Lstr2    = LineStyle('-.', [1. .8 1.]*.8, 2.0, 9);
Lstr3    = LineStyle('-.', [1. 1. .8]*.8, 2.0, 9);
Larray   = LineStyle( '-', [.6 1. .3]*.6, 2.0, 9);
Marrayop = LineStyle( 'o', [1. .6 .3]*1., 2.0, 9);
Mstr1op  = LineStyle( '*', [.8 1. 1.]*.8, 2.0, 9);
Mstr2op  = LineStyle( 'x', [1. .8 1.]*.8, 2.0, 9);
Mstr3op  = LineStyle( '+', [1. 1. .8]*.8, 2.0, 9);

Psun = get(handles.psun, 'Value');
Tamb = get(handles.tamb, 'Value');

axes(handles.axes1);
cla;

        
showP_flag =  get(handles.checkbox1, 'Value');

Pmax = 24e3;
Vmax = 1000;
Vmin = 0;
Imax = 13*3 +1;

%inversor
Vac = 220*sqrt(3);
Vlink = 700;
vinvref = get(handles.vinvref, 'Value'); % tensão imposta plo inversor [V]
deltaref = get(handles.deltaref, 'Value'); % ângulo da tensão impomsta pelo inversor [deg]
inversor = InversorRede(Vlink, 2);

Npt = 1000;
v = Vmin : (Vmax-Vmin) / (Npt-1) : Vmax;

vmppt = get(handles.vmppt, 'Value');
Nmppt = round((vmppt-Vmin)/(Vmax-Vmin)*Npt);


N = [str2double(get(handles.s1, 'String')) , ...
     str2double(get(handles.s2, 'String')) , ...
     str2double(get(handles.s3, 'String')) ] + length(sombra);


str1 = PanelPV();
str2 = PanelPV();
str3 = PanelPV();

str1.Ms = N(1) + sum(1-sombra(:, 1)) - length(sombra);
str2.Ms = N(2) + sum(1-sombra(:, 2)) - length(sombra);
str3.Ms = N(3) + sum(1-sombra(:, 3)) - length(sombra);

str1.solve_i(Psun, Tamb, v);
str2.solve_i(Psun, Tamb, v);
str3.solve_i(Psun, Tamb, v);

iarray = str1.i + str2.i + str3.i;

if showP_flag
    vpot = v;
    ymax = Pmax;
    set(handles.checkbox1, 'String', 'Watt vs Volt');
else
    vpot = ones(size(v));
    ymax = Imax;
    set(handles.checkbox1, 'String', 'Amp vs Volt');
end

Lmppt.plot([vmppt vmppt], [0 ymax]);
hold on
Lstr1.plot(v, str1.i .*vpot );
Lstr2.plot(v, str2.i .*vpot);
Lstr3.plot(v, str3.i .*vpot);
Larray.plot(v, iarray .*vpot);
Mstr1op.plot(v(Nmppt), str1.i(Nmppt) * vpot(Nmppt));
Mstr2op.plot(v(Nmppt), str2.i(Nmppt) * vpot(Nmppt));
Mstr3op.plot(v(Nmppt), str3.i(Nmppt) * vpot(Nmppt));
Marrayop.plot(v(Nmppt), iarray(Nmppt) * vpot(Nmppt));

hold off
ylim([0,ymax])
xlim([Vmin, Vmax])

if showP_flag
    ylabel('Power [W]')
else
    ylabel('Current [A]')
end
xlabel('Voltage [V]')
grid

Istr = [str1.i(Nmppt) , str2.i(Nmppt), str3.i(Nmppt)];
Vstr(1) = min(v(Nmppt) , str1.Ms*str1.Ns*str1.Voc);
Vstr(2) = min(v(Nmppt) , str2.Ms*str2.Ns*str2.Voc);
Vstr(3) = min(v(Nmppt) , str3.Ms*str3.Ns*str3.Voc);

Vpnl(:, 1) = (1-sombra(:,1)) * Vstr(1)/ str1.Ms ;
Vpnl(:, 2) = (1-sombra(:,2)) * Vstr(2)/ str2.Ms ;
Vpnl(:, 3) = (1-sombra(:,3)) * Vstr(3)/ str3.Ms ; 

Ppnl(:, 1) = Vpnl(:, 1) * Istr(1);
Ppnl(:, 2) = Vpnl(:, 2) * Istr(2);
Ppnl(:, 3) = Vpnl(:, 3) * Istr(3);

Pin = iarray(Nmppt) * v(Nmppt);
Iin = sum(Istr);

if get(handles.flag_manual, 'Value') == 1
        [pinv, qinv, iinv, vinv, pgridrot, qgridrot, igridrot, vgridrot, delta] = inversor.SolveV(Vac/sqrt(3), vinvref*(cosd(deltaref)+j*sind(deltaref)));
        
else
    [pinv, qinv, iinv, vinv, pgridrot, qgridrot, igridrot, vgridrot, delta] = inversor.SolveD(Vac/sqrt(3), vinvref*(cosd(deltaref)+j*sind(deltaref)), Pin);

    delta = max(delta, get(handles.deltaref, 'Min'));
    delta = min(delta, get(handles.deltaref, 'Max'));
    set(handles.deltaref, 'Value', delta);
end

flag_vdceq =  abs(Pin-pinv) < 100;   % verifica equilibrio do link dc

        

img = imread('foto.png');
spr = imread('sprite.png');


for m = 1 : arranjo_gui.L
   for n = 1 : arranjo_gui.C
       if sombra(m, n)
           img = mask( img ,                   ...
                       spr ,                   ...
                       arranjo_gui.x0 + (n-1) * arranjo_gui.Dx , ...
                       arranjo_gui.y0 + (m-1) * arranjo_gui.Dy , ...
                       sombra(m,n), ...
                       1);
       end
   end
end




if arranjo_gui.sel(1) > 0 && arranjo_gui.sel(2) > 0
    
    img = highlight( img,                                                      ...
                     arranjo_gui.x0 + (arranjo_gui.sel(2)-1) * arranjo_gui.Dx, ...
                     arranjo_gui.y0 + (arranjo_gui.sel(1)-1) * arranjo_gui.Dy, ...
                     arranjo_gui.Dx, arranjo_gui.Dy );
                 
    set(handles.arr_text, 'String', sprintf( 'painel %d da string %d', arranjo_gui.sel(1), arranjo_gui.sel(2) ));                 
    set(handles.psel_val, 'String', sprintf('%3.0f W', Ppnl(arranjo_gui.sel(1), arranjo_gui.sel(2))) );
    set(handles.vsel_val, 'String', sprintf('%2.1f V', Vpnl(arranjo_gui.sel(1), arranjo_gui.sel(2))) );
    set(handles.isel_val, 'String', sprintf('%2.1f A', Istr(arranjo_gui.sel(2))) );
    set(handles.str_text, 'String', sprintf('string %d:', arranjo_gui.sel(2) ));
    set(handles.vstrsel_val, 'String', sprintf('%3.0f V', Vstr(arranjo_gui.sel(2))) );
    set(handles.pstrsel_val, 'String', sprintf('%4.0f W', Vstr(arranjo_gui.sel(2)) * Istr(arranjo_gui.sel(2))  ));  %, Vstr(arranjo_gui.sel(2)) * Istr(arranjo_gui.sel(2)) / Pin *100  ));
    set(handles.istrsel_val, 'String', sprintf('%2.1f A', Istr(arranjo_gui.sel(2))) );
else
    set(handles.arr_text, 'String', 'nenhum selecionado');
    set(handles.psel_val, 'String', '');
    set(handles.vsel_val, 'String', '');
    set(handles.isel_val, 'String', '');
    set(handles.str_text, 'String', '');
    set(handles.vstrsel_val, 'String', '');
    set(handles.pstrsel_val, 'String', '');
    set(handles.istrsel_val, 'String', '');
end

axes(handles.axes2);
imh = image( img );
axis off
axis image
set(imh,'ButtonDownFcn', {@click, handles});


set(handles.psun_val, 'String', sprintf( '%3.0f W/m²', Psun) );
set(handles.tamb_val, 'String', sprintf( '%2.1f °C', Tamb) );

set(handles.vin_val, 'String', sprintf( '%4.0f V', vmppt) );
set(handles.iin_val, 'String', sprintf( '%2.1f A', Iin) );
set(handles.pin_val, 'String', sprintf( '%2.1f kW', Pin/1000) );

set(handles.istr1_val, 'String', sprintf( '%2.1f A', Istr(1)) );
set(handles.istr2_val, 'String', sprintf( '%2.1f A', Istr(2)) );
set(handles.istr3_val, 'String', sprintf( '%2.1f A', Istr(3)) );

set(handles.pstr1_val, 'String', sprintf( '%1.1f kW', Istr(1) * vmppt/1000) );
set(handles.pstr2_val, 'String', sprintf( '%1.1f kW', Istr(2) * vmppt/1000) );
set(handles.pstr3_val, 'String', sprintf( '%1.1f kW', Istr(3) * vmppt /1000) );

if flag_vdceq
    set(handles.vlink_val, 'String', sprintf( '%2.0f V', Vlink ) );
else
    set(handles.vlink_val, 'String', '?????');
end
set(handles.t11, 'String', sprintf( '%2.0f V', Vpnl(1,1) ) );
set(handles.t21, 'String', sprintf( '%2.0f V', Vpnl(2,1) ) );
set(handles.t31, 'String', sprintf( '%2.0f V', Vpnl(3,1) ) );
set(handles.t41, 'String', sprintf( '%2.0f V', Vpnl(4,1) ) );

set(handles.t12, 'String', sprintf( '%2.0f V', Vpnl(1,2) ) );
set(handles.t22, 'String', sprintf( '%2.0f V', Vpnl(2,2) ) );
set(handles.t32, 'String', sprintf( '%2.0f V', Vpnl(3,2) ) );
set(handles.t42, 'String', sprintf( '%2.0f V', Vpnl(4,2) ) );

set(handles.t13, 'String', sprintf( '%2.0f V', Vpnl(1,3) ) );
set(handles.t23, 'String', sprintf( '%2.0f V', Vpnl(2,3) ) );
set(handles.t33, 'String', sprintf( '%2.0f V', Vpnl(3,3) ) );
set(handles.t43, 'String', sprintf( '%2.0f V', Vpnl(4,3) ) );

set(handles.pinv_val, 'String', sprintf( '%2.1f kW', pinv /1000) );
set(handles.qinv_val, 'String', sprintf( '%2.1f kVAr', qinv /1000) );
set(handles.iinv_val, 'String', sprintf( '%2.1f A < %2.1f°', abs(iinv), angle(iinv)*180/pi) );
set(handles.vinv_val, 'String', sprintf( '%3.0f V < %2.1f°', abs(vinv), angle(vinv)*180/pi) );

