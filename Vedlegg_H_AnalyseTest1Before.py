import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# LES DATA FRA CSV FIL
df = pd.read_csv(r"C:\Users\danie\OneDrive\Skrivebord\DatasettTest1.csv",
                 header=None,
                 names=["CupId", "OrderId", "CupNo", "Color", "WaterPercentage", "WeightDifference", "RealWeight", "TimeSpentMinutes"],
                 sep=";",
                 decimal=",")
df["TimeSpentMinutes"] = pd.to_numeric(df["TimeSpentMinutes"], errors='coerce')

# Convert to seconds
df["TimeSpentSeconds"] = df["TimeSpentMinutes"] * 60

WEIGHT_AT_100_PERCENT_G = 29.22
CUP_WEIGHT_G = 15.21
NET_WEIGHT_AT_100_PERCENT_G = WEIGHT_AT_100_PERCENT_G - CUP_WEIGHT_G  # = 13g

df["TargetWeight"] = CUP_WEIGHT_G + (df["WaterPercentage"] / 100) * NET_WEIGHT_AT_100_PERCENT_G
df["WeightDifference"] = df["RealWeight"] - df["TargetWeight"]

print(f"Manglende verdier:\n{df.isnull().sum()}")
# OUTLIERS PÅ WeightDifference
abs_diff = df['WeightDifference'].abs()
Q1 = abs_diff.quantile(0.25)
Q3 = abs_diff.quantile(0.75)
IQR = Q3 - Q1
outliers_weight = df[abs_diff > Q3 + 1.5 * IQR]

# OUTLIERS PÅ TimeSpentMinutes
Q1 = df['TimeSpentMinutes'].quantile(0.25)
Q3 = df['TimeSpentMinutes'].quantile(0.75)
IQR = Q3 - Q1
outliers_time = df[(df['TimeSpentMinutes'] < Q1 - 1.5 * IQR) | (df['TimeSpentMinutes'] > Q3 + 1.5 * IQR)]

outliers = pd.concat([outliers_weight, outliers_time]).drop_duplicates()
df_with_outliers_removed = df.drop(outliers.index)
print("\n" + f"Antall outliers funnet: {len(outliers)}" + "\n")
#print(outliers)

# PROSENTVIS FEIL
df_with_outliers_removed = df_with_outliers_removed.copy()
df_with_outliers_removed["ErrorPercent"] = (df_with_outliers_removed["WeightDifference"].abs() / (df_with_outliers_removed["RealWeight"] - CUP_WEIGHT_G)) * 100

# STATISTIKK
statistics = df[["WeightDifference", "TimeSpentMinutes"]].describe()
statistics_outliers_removed = df_with_outliers_removed[["WeightDifference", "TimeSpentMinutes", "ErrorPercent"]].describe()

# Fjerner koppene med 10% fylling, brukes i Analyse-kapittel
df_trimmed_no10percentcups = df_with_outliers_removed.drop(df_with_outliers_removed[df_with_outliers_removed["WaterPercentage"] == 10].index)
# %%
def get_weight_MAE(df: pd.DataFrame) -> float:
    return df['WeightDifference'].abs().mean()

def get_mean_error_percent(df: pd.DataFrame) -> float:
    return df['ErrorPercent'].mean()

def plot_weight_error(df: pd.DataFrame):
    errors = df['WeightDifference'].sort_values().reset_index(drop=True)
    plt.figure(figsize=(10, 5))
    plt.bar(errors.index, errors.values)
    plt.xlabel('Flaske nummer sortert etter netto vektavvik')
    plt.ylabel('Netto vektavvik [g]')
    plt.title('Distribusjon av netto vektavvik [g] (sortert stigende)')
    plt.tight_layout()
    plt.grid(axis='y')
    plt.show()

def plot_time_distribution(df: pd.DataFrame):
    plt.figure(figsize=(10, 5))
    plt.hist(df['TimeSpentSeconds'], bins=10, edgecolor='black', rwidth=0.5)
    plt.xlabel('Syklustid per kopp (sekunder)')
    plt.ylabel('Antall kopper med denne tiden')
    plt.title('Distribusjon av syklustid per kopp')
    plt.xticks(np.arange(40, df['TimeSpentSeconds'].max() + 0.5, step=0.5))
    plt.yticks(np.arange(0, 30, step=2))
    plt.tight_layout()
    plt.grid(axis='y')
    plt.show()

def plot_error_percent(df: pd.DataFrame):
    errors = df['ErrorPercent'].abs().sort_values().reset_index(drop=True)
    plt.figure(figsize=(10, 5))
    plt.bar(errors.index, errors.values)
    plt.xlabel('Flaske (sortert etter vektavvik i %)')
    plt.ylabel('Netto vektavvik [%]')
    plt.title('Netto vektavvik som prosent av fyllnivå (sortert stigende)')
    plt.tight_layout()
    plt.grid(axis='y')
    plt.show()

def plot_error_by_cup(df: pd.DataFrame):
    fill_levels = {i: f'Kopp {i}\n({i*10}%)' for i in range(1, 11)}
    avg_error = df.groupby('CupNo')['ErrorPercent'].mean().reindex(range(1, 11))
    plt.figure(figsize=(10, 5))
    plt.bar(avg_error.index, avg_error.values)
    plt.xlabel('Kopp nummer / Fyllnivå')
    plt.ylabel('Gjennomsnittlig netto avvik (MAPE) [%]')
    plt.title('Gjennomsnittlig netto avvik (MAPE) % for hver kopp nummer')
    plt.xticks(range(1, 11), [fill_levels[i] for i in range(1, 11)])
    plt.tight_layout()
    plt.grid(axis='y')
    plt.show()
    
def plot_abs_error_by_cup(df: pd.DataFrame):
    fill_levels = {i: f'Kopp {i}\n({i*10}%)' for i in range(1, 11)}
    avg_error = df.groupby('CupNo')['WeightDifference'].apply(lambda x: x.mean()).reindex(range(1, 11))
    plt.figure(figsize=(10, 5))
    plt.bar(avg_error.index, avg_error.values)
    plt.xlabel('Kopp nummer / Fyllnivå [%]')
    plt.ylabel('Gjennomsnittlig vektavvik per fyllingsgrad [g]')
    plt.title('Gjennomsnittlig vektavvik per fyllingsgrad [g]')
    plt.xticks(range(1, 11), [fill_levels[i] for i in range(1, 11)])
    plt.tight_layout()
    plt.grid(axis='y')
    plt.show()
    
# KJØR PLOTS
plot_weight_error(df_with_outliers_removed)
plot_time_distribution(df_with_outliers_removed)
plot_error_percent(df_with_outliers_removed)
plot_error_by_cup(df_with_outliers_removed)
plot_abs_error_by_cup(df_with_outliers_removed)

# PRINT RESULTATER
MAE_weight = get_weight_MAE(df_with_outliers_removed)
mean_error_pct = get_mean_error_percent(df_with_outliers_removed)
print(f"MAE vekt: {MAE_weight:.2f}g")
print(f"MAPE: {mean_error_pct:.2f}%")
#print(statistics_outliers_removed)
print(get_mean_error_percent(df_trimmed_no10percentcups))
