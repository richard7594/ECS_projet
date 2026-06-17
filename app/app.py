
from datetime import date
from dash import Dash, html, dcc, Input, Output, callback

app = Dash(__name__)
app.title = "Joyeux Anniversaire 🎂"

COLORS = {
    "fond": "#fff0f6",
    "primaire": "#d6336c",
    "secondaire": "#f8b400",
    "texte": "#3b0a45",
}

app.layout = html.Div(
    style={
        "backgroundColor": COLORS["fond"],
        "minHeight": "100vh",
        "fontFamily": "'Comic Sans MS', 'Trebuchet MS', sans-serif",
        "display": "flex",
        "justifyContent": "center",
        "alignItems": "center",
        "padding": "40px 20px",
    },
    children=[
        html.Div(
            style={
                "backgroundColor": "white",
                "borderRadius": "20px",
                "padding": "40px",
                "maxWidth": "480px",
                "width": "100%",
                "boxShadow": "0 10px 30px rgba(214, 51, 108, 0.25)",
                "textAlign": "center",
                "border": f"3px dashed {COLORS['secondaire']}",
            },
            children=[
                html.H1(
                    "🎉 Joyeux Anniversaire 🎂",
                    style={"color": COLORS["primaire"], "marginBottom": "5px"},
                ),
                html.P(
                    "Entre ton prénom et ta date de naissance !",
                    style={"color": COLORS["texte"], "marginBottom": "25px"},
                ),

                dcc.Input(
                    id="prenom",
                    type="text",
                    placeholder="Ton prénom",
                    style={
                        "width": "90%",
                        "padding": "10px",
                        "borderRadius": "10px",
                        "border": f"2px solid {COLORS['primaire']}",
                        "marginBottom": "15px",
                        "fontSize": "16px",
                    },
                ),

                html.Br(),

                dcc.DatePickerSingle(
                    id="date-naissance",
                    placeholder="Date de naissance",
                    display_format="DD/MM/YYYY",
                    style={"marginBottom": "20px"},
                ),

                html.Br(), html.Br(),

                html.Button(
                    "🎈 Découvrir la surprise 🎈",
                    id="bouton-valider",
                    n_clicks=0,
                    style={
                        "backgroundColor": COLORS["primaire"],
                        "color": "white",
                        "border": "none",
                        "padding": "12px 25px",
                        "borderRadius": "30px",
                        "fontSize": "16px",
                        "cursor": "pointer",
                        "fontWeight": "bold",
                    },
                ),

                html.Div(id="resultat", style={"marginTop": "30px", "fontSize": "18px"}),
            ],
        )
    ],
)


@callback(
    Output("resultat", "children"),
    Input("bouton-valider", "n_clicks"),
    Input("prenom", "value"),
    Input("date-naissance", "date"),
)
def afficher_message(n_clicks, prenom, date_naissance):
    if n_clicks == 0:
        return ""

    if not prenom or not date_naissance:
        return html.P(
            "Merci de remplir ton prénom et ta date de naissance 🎁",
            style={"color": "red"},
        )

    naissance = date.fromisoformat(date_naissance)
    aujourdhui = date.today()

    age = aujourdhui.year - naissance.year - (
        (aujourdhui.month, aujourdhui.day) < (naissance.month, naissance.day)
    )

    prochain_anniversaire = date(aujourdhui.year, naissance.month, naissance.day)
    if prochain_anniversaire < aujourdhui:
        prochain_anniversaire = date(aujourdhui.year + 1, naissance.month, naissance.day)

    jours_restants = (prochain_anniversaire - aujourdhui).days

    if jours_restants == 0:
        message = f"🥳 Aujourd'hui, {prenom} fête ses {age + 1} ans !! Bon anniversaire !! 🎂"
    else:
        message = (
            f"✨ Salut {prenom} ! Tu as {age} ans.\n"
            f"Plus que {jours_restants} jour(s) avant ton prochain anniversaire ! 🎈"
        )

    return html.Div(
        [
            html.P(message, style={"whiteSpace": "pre-line", "color": COLORS["texte"]}),
            html.Div("🎁🎉🎈🎂🥳", style={"fontSize": "30px", "marginTop": "10px"}),
        ]
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=True)