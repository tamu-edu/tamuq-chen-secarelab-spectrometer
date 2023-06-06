import dash
from dash import dcc, html
from dash.dependencies import Input, Output, State
import plotly.graph_objs as go
import pandas as pd
import os
from datetime import datetime
import threading

app = dash.Dash(__name__)

# Global variables
bg_spectrum = []
curr_spectrum = []
is_collecting = False
start_time = None

# Utility functions
def collect_spec():
    # Replace with your actual function
    import random
    wavelengths = list(range(1, 1001, 5))
    intensities = [random.random() for _ in wavelengths]
    spectrum = [wavelengths, intensities]
    return spectrum

def save_spec(filename, spectrum):
    # Get the current timestamp
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    # Create a DataFrame from the wavelengths and spectrum
    dfwv = pd.DataFrame(['time'] + spectrum[0]).T
    df = pd.DataFrame([timestamp] + spectrum[1]).T

    # Check if the file exists
    if os.path.exists(filename):
        # If the file exists, append the data without the header
        df.to_csv(filename, mode='a', header=False, index=False)
    else:
        # If the file doesn't exist, write the data with the header
        dfwv.to_csv(filename, mode='w', header=False, index=False)
        df.to_csv(filename, mode='a', header=False, index=False)

def save_spect(filename, spectrum):
    # Replace with your actual function
    pass

# Layout
app.layout = html.Div([
    html.Div([
        dcc.Input(id='lower_wv', type='text', placeholder='lower_wv', value=200),
        dcc.Input(id='upper_wv', type='text', placeholder='upper_wv', value=500),
        dcc.Input(id='time_step', type='text', placeholder='time_step'),
        dcc.Input(id='filename', type='text', placeholder='filename'),
        html.Label(id='timer', children='0'),
        ], style={'width': '20%', 'display': 'flex', 'flex-direction': 'column'}),
    html.Div([
        html.Button('BACKGROUND', id='bg-button', n_clicks=0),
        html.Button('CURRENT', id='curr-button', n_clicks=0),
        html.Button('START', id='start-button', n_clicks=0),
        html.Button('STOP', id='stop-button', n_clicks=0),
        html.Button('CLEAR BG', id='clear-bg-button', n_clicks=0),
        ], style={'width': '100%', 'display': 'flex', 'justify-content': 'space-around'}), 
    html.Div([
        dcc.Graph(id='graph', config={'displayModeBar': False}, figure={'data': [], 'layout': {}}),
        dcc.Interval(
            id='interval-component',
            interval=10*1000, # in milliseconds
            n_intervals=0
        )
        ], style={'width': '100%', 'height': '100%'}),
    html.Div([
        dcc.Graph(id='graphbg', config={'displayModeBar': False}, figure={'data': [], 'layout': {}}),
        ], style={'width': '100%'}),
    dcc.ConfirmDialog(
        id='confirm',
        message='The filename is empty.',
    ),
])

# Callbacks
@app.callback(
    [Output('graph', 'figure'),
     Output('graphbg', 'figure')],
    [Input('bg-button', 'n_clicks'),
     Input('curr-button', 'n_clicks'),
     Input('clear-bg-button', 'n_clicks'),
     Input('interval-component', 'n_intervals')],
    [State('filename', 'value'),
     State('graph', 'figure'),
     State('graphbg', 'figure'),
     State('lower_wv', 'value'),
     State('upper_wv', 'value'),]
)
def update_graph(bg_clicks, curr_clicks, clear_bg_clicks, n_intervals, filename, figure, figurebg, lower_wv, upper_wv):
    global bg_spectrum, curr_spectrum, is_collecting

    ctx = dash.callback_context
    button_id = ctx.triggered[0]['prop_id'].split('.')[0]

    if button_id == 'bg-button':
        bg_spectrum = collect_spec()
        figurebg['data'] = [go.Scatter(x=bg_spectrum[0], y=bg_spectrum[1], name='Background')]
        
    elif button_id == 'curr-button' or (button_id == 'interval-component' and is_collecting):
        curr_spectrum = collect_spec()
        curr_spectrum[1] = [a - b for a, b in zip(curr_spectrum[1], bg_spectrum[1])]
        save_spec(filename, curr_spectrum)
        if button_id == 'curr-button':
            labeltxt = curr_clicks
        elif button_id == 'interval-component' and is_collecting:
            labeltxt = n_intervals
        figure['data'].append(go.Scatter(x=curr_spectrum[0], y=curr_spectrum[1], name=f'Current {labeltxt}'))
    elif button_id == 'clear-bg-button' and figure['data']:
        figure['data'] = figure['data'][1:]
        
    figurebg['layout']['xaxis'] = {'range': [lower_wv, upper_wv]}
    figure['layout']['xaxis'] = {'range': [lower_wv, upper_wv]}

    return figure, figurebg

@app.callback(
    Output('interval-component', 'max_intervals'),
    [Input('start-button', 'n_clicks'),
     Input('stop-button', 'n_clicks')]
)
def control_collection(start_clicks, stop_clicks):
    global is_collecting

    ctx = dash.callback_context
    button_id = ctx.triggered[0]['prop_id'].split('.')[0]

    if button_id == 'start-button':
        is_collecting = True
    elif button_id == 'stop-button':
        is_collecting = False

    return -1 if is_collecting else 0

@app.callback(
    Output('timer', 'children'),
    [Input('start-button', 'n_clicks'),
     Input('stop-button', 'n_clicks'),
     Input('interval-component', 'n_intervals')]
)
def update_timer(start_clicks, stop_clicks, n_intervals):
    global start_time

    ctx = dash.callback_context
    button_id = ctx.triggered[0]['prop_id'].split('.')[0]

    if button_id == 'start-button':
        start_time = datetime.now()
    elif button_id == 'stop-button':
        start_time = None

    if start_time is not None:
        elapsed_time = datetime.now() - start_time
        return str(elapsed_time)

    return '0'


@app.callback(
    Output('confirm', 'displayed'),
    [Input('curr-button', 'n_clicks'),
     Input('start-button', 'n_clicks')],
    [State('filename', 'value')]
)
def display_confirm(curr_clicks, start_clicks, filename):
    ctx = dash.callback_context
    button_id = ctx.triggered[0]['prop_id'].split('.')[0]

    if button_id in ['curr-button', 'start-button'] and not filename:
        return True

    return False


if __name__ == '__main__':
    app.run_server(debug=True)
