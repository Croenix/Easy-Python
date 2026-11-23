importScripts('./0.27.8/pyodide.js');

let pyodide;
const blockedModules = [
  'os', 'sys', 'subprocess', 'socket', 'pathlib', 'open', 'io', 'builtins',
  'importlib', 'urllib', 'http', 'requests', 'js', 'pyodide', 'webbrowser',
];

async function initialize() {
  const indexURL = new URL('./0.27.8/', self.location.href).href;
  pyodide = await loadPyodide({indexURL});
  self.postMessage({type: 'ready'});
}

async function run(message) {
  const {id, source, inputs} = message;
  if (typeof source !== 'string' || source.length > 65536) {
    self.postMessage({id, type: 'result', stdout: '', stderr: '', error: 'Code is too long.'});
    return;
  }
  pyodide.globals.set('__easy_source', source);
  pyodide.globals.set('__easy_inputs', pyodide.toPy(Array.isArray(inputs) ? inputs.slice(0, 32) : []));
  const runner = `
import ast, builtins, contextlib, io

class _EasyBlockedOperation(Exception):
    pass

_easy_original_import = builtins.__import__
_easy_blocked = set(${JSON.stringify(blockedModules)})
def _easy_import(name, globals=None, locals=None, fromlist=(), level=0):
    if name.split('.')[0] in _easy_blocked:
        raise ImportError('This module is not available in the learning runner.')
    return _easy_original_import(name, globals, locals, fromlist, level)

def _easy_no_files(*args, **kwargs):
    raise PermissionError('File access is disabled in the learning runner.')

_easy_builtins = dict(vars(builtins))
_easy_builtins.pop('open', None)
_easy_builtins['__import__'] = _easy_import
_easy_input_values = list(__easy_inputs)
def _easy_input(prompt=''):
    if not _easy_input_values:
        raise EOFError('No more sample input was provided.')
    return str(_easy_input_values.pop(0))
_easy_builtins['input'] = _easy_input

_easy_output = io.StringIO()
try:
    _easy_tree = ast.parse(__easy_source, mode='exec')
    for _easy_node in ast.walk(_easy_tree):
        if isinstance(_easy_node, (ast.Import, ast.ImportFrom)):
            _easy_names = [alias.name.split('.')[0] for alias in _easy_node.names] if isinstance(_easy_node, ast.Import) else [_easy_node.module.split('.')[0] if _easy_node.module else '']
            if any(name in _easy_blocked for name in _easy_names):
                raise ImportError('This module is not available in the learning runner.')
        if isinstance(_easy_node, ast.Call) and isinstance(_easy_node.func, ast.Name) and _easy_node.func.id in ('open', 'eval', 'exec', 'compile'):
            if _easy_node.func.id != 'exec':
                raise PermissionError('This operation is disabled in the learning runner.')
    _easy_namespace = {'__builtins__': _easy_builtins}
    with contextlib.redirect_stdout(_easy_output):
        exec(compile(_easy_tree, '<learner-code>', 'exec'), _easy_namespace, _easy_namespace)
    _easy_result = {'stdout': _easy_output.getvalue()[:65536], 'stderr': '', 'error': None}
except BaseException as _easy_error:
    _easy_result = {'stdout': _easy_output.getvalue()[:65536], 'stderr': '', 'error': str(_easy_error), 'errorType': type(_easy_error).__name__, 'line': getattr(_easy_error, 'lineno', None)}
_easy_result
`;
  try {
    const result = await pyodide.runPythonAsync(runner);
    const json = result.toJs({dict_converter: Object.fromEntries});
    result.destroy();
    self.postMessage({id, type: 'result', ...json});
  } catch (error) {
    self.postMessage({id, type: 'result', stdout: '', stderr: '', error: String(error)});
  } finally {
    pyodide.globals.delete('__easy_source');
    pyodide.globals.delete('__easy_inputs');
  }
}

self.onmessage = (event) => {
  run(event.data);
};

initialize().catch((error) => self.postMessage({type: 'workerError', error: String(error)}));
