const SAMPLES_FOR_DIST_NORMER = 50000;

sample(df::DataFrame) = @inbounds df[rand(1:nrow(df), SAMPLES_FOR_DIST_NORMER), :];

other(i::Int) = ifelse(i == 1, 2, 1);

load_dfs(base, fp) = [ParquetFiles.load(joinpath(base, fp, "$i.parquet")) |> DataFrame for i = 0:1];

col_dist(x::String, y::String) = evaluate(normalize(Levenshtein()), x::String, y::String);
col_dist(x::Number, y::Number) = abs(x - y);