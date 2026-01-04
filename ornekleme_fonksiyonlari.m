function X = ornekleme_fonksiyonlari(method, N, d, seed)
% ORNEKLEME_FONKSIYONLARI  Seçilen yönteme göre [0,1]^d uzayında N adet örnek üretir
%
% method : "mc", "lhs", "sobol" veya "halton"
% N      : örnek sayısı
% d      : boyut sayısı
% seed   : rastgelelik tohumu (opsiyonel)

    if nargin < 4
        seed = [];
    end

    method = lower(string(method));

    switch method
        case "mc"
            % Monte Carlo: tamamen rastgele örnekleme
            if ~isempty(seed), rng(seed); end
            X = rand(N, d);

        case "lhs"
            % Latin Hypercube Sampling (LHS)
            if ~isempty(seed), rng(seed); end

            if exist("lhsdesign", "file") == 2
                X = lhsdesign(N, d);
            else
                X = lhs_fallback(N, d);
            end

            % Sobol (düşük ayrışımlı) örnekleme
            case "sobol"
    if exist("sobolset", "file") ~= 2
        error("sobolset bulunamadı. Statistics Toolbox yok olabilir.");
    end
    p = sobolset(d);
    p = scramble(p, "MatousekAffineOwen");
    p.Skip = 1000;   % ilk 1000 noktayı atla (dalgalanma azalır)
    X = net(p, N);

            % Halton örnekleme

        case "halton"
    if exist("haltonset", "file") ~= 2
        error("haltonset bulunamadı. Statistics Toolbox yok olabilir.");
    end

    p = haltonset(d);
    p = scramble(p, "RR2");
    p.Skip = 1000;   % ilk 1000 noktayı atla
    X = net(p, N);


        otherwise
            error("Bilinmeyen method girdin: %s", method);
    end
end

function X = lhs_fallback(N, d)
% LHS için basit yedek implementasyon (toolbox yoksa çalışır)

    X = zeros(N, d);

    for j = 1:d
        perm = randperm(N);
        u = rand(N, 1);
        X(:, j) = (perm(:) - u) / N;
    end
end
