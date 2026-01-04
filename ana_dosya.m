clear; clc;
% Kullanılacak örnekleme yöntemleri
methods = ["mc","lhs","sobol","halton"];
% İncelenecek boyutlar
d_list = [5 10 20 30 50];

% Örnek sayıları
N_list = [128 256 512 1024 2048 4096];

% Sonuçları saklamak için yapı
results = struct();

for di = 1:length(d_list)
    d = d_list(di);

    fprintf('\n=============================\n');
    fprintf(' Boyut d = %d\n', d);
    fprintf('=============================\n');
 % Sobol G fonksiyonu için parametre vektörü
   a = zeros(1,d);
   a(1:4) = [0 1 4.5 9];
   a(5:end) = linspace(20, 100, d-4);

      % Referans değer (çok büyük Sobol örneklemesiyle yaklaşık gerçek)
    Xref = ornekleme_fonksiyonlari("sobol", 2^14, d, 1);
    yref = sobol_g(Xref, a);
    mu_ref = mean(yref);

    % Bu boyut için hata matrisi: satır=N, sütun=method
    err_mean = zeros(length(N_list), length(methods));
    err_std  = zeros(length(N_list), length(methods));
    time_mean = zeros(length(N_list), length(methods));
    time_std  = zeros(length(N_list), length(methods));

    for ni = 1:length(N_list)
        N = N_list(ni);
        fprintf('\nN = %d\n', N);

        for mi = 1:length(methods)
            method = methods(mi);

            % tekrar sayısı
            if method == "mc" || method == "lhs"
                R = 10;
            else
                R = 1;  % istersen 3 yapabilirsin
            end
            errs = zeros(R,1);
            times = zeros(R,1);
         for r = 1:R
             tStart = tic;

            X = ornekleme_fonksiyonlari(method, N, d, r);
            y = sobol_g(X, a);
            mu_hat = mean(y);

            times(r) = toc(tStart);
            errs(r)  = abs(mu_hat - mu_ref);
    
         end

            err_mean(ni, mi) = mean(errs);
            err_std(ni, mi)  = std(errs);
            time_mean(ni, mi) = mean(times);
            time_std(ni, mi)  = std(times);

            fprintf('  %-6s ortalama hata = %.3e\n', method, err_mean(ni, mi));
        end
    end

    % Sonuçları results içine koy
    results(di).d = d;
    results(di).N_list = N_list;
    results(di).methods = methods;
    results(di).err_mean = err_mean;
    results(di).err_std  = err_std;
    results(di).time_mean = time_mean;
    results(di).time_std  = time_std;
end

% Sonuçları dosyaya kaydet (sonradan rapor için rahat)
save('sonuclar.mat', 'results');

%% 4) ÖRNEK DAĞILIM SCATTER PLOT'LARI (MC / LHS / SOBOL / HALTON)

% Yöntemlere sabit renk atama (4 yöntem için 4 farklı renk)
C = lines(length(methods));   % MATLAB'ın hazır renk seti

% Scatter için kullanılacak örnek sayısı (çok büyük yapma, grafik ağırlaşır)
N_scatter = 1024;

% Her boyut için (d_list içindeki) örnek dağılımını çiz
for di = 1:length(d_list)
    d = d_list(di);

    % d en az 2 değilse 2D scatter çizilemez
    if d < 2
        continue;
    end

    % -------- 2D Scatter: x1 - x2 --------
    figure('Name', sprintf('2D Scatter (x1-x2) d=%d', d));

    for mi = 1:length(methods)
        method = methods(mi);

        % Örnek üret
        Xs = ornekleme_fonksiyonlari(method, N_scatter, d, 1);

        subplot(2,2,mi);
        scatter(Xs(:,1), Xs(:,2), 12, ...
    'filled', ...
    'MarkerFaceColor', C(mi,:), ...
    'MarkerEdgeColor', C(mi,:));

        grid on;
        axis([0 1 0 1]);
        axis square;

        xlabel('x_1');
        ylabel('x_2');
        title(sprintf('%s (N=%d, d=%d)', method, N_scatter, d));
    end

    % İstersen otomatik kaydet (proje klasörüne png)
    saveas(gcf, sprintf('scatter2D_d%d_N%d.png', d, N_scatter));

    % -------- 3D Scatter: x1 - x2 - x3 (opsiyonel) --------
    if d >= 3
        figure('Name', sprintf('3D Scatter (x1-x2-x3) d=%d', d));

        for mi = 1:length(methods)
            method = methods(mi);

            Xs = ornekleme_fonksiyonlari(method, N_scatter, d, 1);

            subplot(2,2,mi);
            scatter3(Xs(:,1), Xs(:,2), Xs(:,3), 12, ...
             'filled', ...
             'MarkerFaceColor', C(mi,:), ...
             'MarkerEdgeColor', C(mi,:));

            grid on;
            xlim([0 1]); ylim([0 1]); zlim([0 1]);

            xlabel('x_1');
            ylabel('x_2');
            zlabel('x_3');
            title(sprintf('%s (N=%d, d=%d)', method, N_scatter, d));
            view(45, 25);
        end

        saveas(gcf, sprintf('scatter3D_d%d_N%d.png', d, N_scatter));
    end
end

% ---- Tüm boyutları tek figürde alt alta çiz ----
figure;

for di = 1:length(results)

    d = results(di).d;
    N_list = results(di).N_list;
    methods = results(di).methods;
    err_mean = results(di).err_mean;
    err_std  = results(di).err_std;

    subplot(length(results),1,di);  % alt alta grafik
    hold on;

    for mi = 1:length(methods)
        % log x ekseni, y lineer + hata çubuğu
        errorbar(N_list, err_mean(:,mi), err_std(:,mi), '-o', ...
            'LineWidth', 1.5, ...
             'MarkerSize', 8, ...
            'DisplayName', methods(mi));
    end

    set(gca,'XScale','log');   % x ekseni log, y ekseni log
    set(gca,'YScale','log');
    grid on;
    xlabel('N (örnek sayısı)');
    ylabel('Mutlak Hata');
    title(sprintf('Yakınsama Grafiği (d = %d)', d));
    legend('Location','northeast');
end
%% HATA - ZAMAN GRAFİĞİ (Time-to-Accuracy)
figure('Name','Hata - Zaman');

for mi = 1:length(methods)
    method = methods(mi);

    subplot(2,2,mi);
    hold on;

    for di = 1:length(results)
        d = results(di).d;

        t = results(di).time_mean(:,mi);  % süre
        e = results(di).err_mean(:,mi);   % hata

        % eps yok: log çizimde 0/negatif varsa çizmesin diye NaN yapıyoruz
        t(t<=0) = NaN;
        e(e<=0) = NaN;

        loglog(t, e, '-o', ...
            'LineWidth', 1.5, 'MarkerSize', 8, ...
            'DisplayName', sprintf('d=%d', d));
    end

    grid on;
    xlabel('Süre (s)');
    ylabel('Mutlak Hata');
    title(sprintf('Hata - Zaman (%s)', method));
    legend('Location','northeast');
    hold off;

end
