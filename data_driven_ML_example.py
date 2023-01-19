import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder

# Chargement des données dans un dataframe pandas
data = pd.read_csv("marketing_data.csv")

# Création d'un champ 'converted' basé sur l'existence du champ Date
data['converted'] = ~data['Date'].isna()

# Encoder en un champs 'channel'
encoder = OneHotEncoder()
channel_encoded = encoder.fit_transform(data[['channel']])
channel_df = pd.DataFrame(channel_encoded.toarray(), columns=encoder.get_feature_names_out(['channel']))

# Concaténez les données encodées avec les données originales
data = pd.concat([data, channel_df], axis=1)

# Séparez les données en ensembles d'entraînement et de test
X_train, X_test, y_train, y_test = train_test_split(data.drop(['converted', 'channel','Date'], axis=1), data['converted'], test_size=0.2)

# Entraînez un classificateur de forêt aléatoire sur les données d'entraînement
clf = RandomForestClassifier()
clf.fit(X_train, y_train)

# Utilisez le modèle entraîné pour prédire la probabilité de conversion pour chaque canal
probs = clf.predict_proba(X_test)

# Attribuez un score de contribution à chaque canal
contributions = probs[:,1] * X_test[channel_df.columns]

# Affichez les scores de contribution pour chaque canal (channel)
for channel in channel_df.columns:
    print(f"{channel} contribution:", contributions[channel].sum())
