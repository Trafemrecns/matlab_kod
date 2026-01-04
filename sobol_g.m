function y = sobol_g(X, a)
% SOBOL_G  Sobol G test fonksiyonu
% G(x) = ∏ ( |4*x_i - 2| + a_i ) / (1 + a_i)
%
% Girdi:
%   X : N x d boyutlu matris, her eleman [0,1] aralığında
%   a : 1 x d boyutlu parametre vektörü
%
% Çıktı:
%   y : N x 1 boyutlu sonuç vektörü

    % X'in boyutlarını al
    [N, d] = size(X);

    % a vektörünün uzunluğu d ile uyumlu mu kontrol et
    if length(a) ~= d
        error('a vektörünün uzunluğu X sütun sayısına eşit olmalıdır.');
    end

    % |4*x_i - 2| + a_i ifadesini hesapla
    Y = abs(4*X - 2) + a;

    % (1 + a_i) ile böl
    Y = Y ./ (1 + a);

    % Her satır için çarpımı al (boyutlar boyunca)
    y = prod(Y, 2);
    
