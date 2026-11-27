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
  const {id, source, inputs, files = {}} = message;
  const projectSize = Object.values(files).reduce((size, value) => size + String(value).length, 0);
  if (typeof source !== 'string' || source.length > 65536 || projectSize > 262144) {
    self.postMessage({id, type: 'result', stdout: '', stderr: '', error: 'Code is too long.'});
    return;
  }
  pyodide.globals.set('__easy_source', source);
  pyodide.globals.set('__easy_inputs', pyodide.toPy(Array.isArray(inputs) ? inputs.slice(0, 32) : []));
  pyodide.globals.set('__easy_files', pyodide.toPy(files));
  const runner = `
import ast, builtins, contextlib, io, re, types

class _EasyBlockedOperation(Exception):
    pass

_easy_original_import = builtins.__import__
_easy_blocked = set(${JSON.stringify(blockedModules)})
_easy_project_files = {}
for _easy_filename, _easy_contents in dict(__easy_files).items():
    if isinstance(_easy_filename, str) and _easy_filename.endswith('.py') and re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*\.py', _easy_filename):
        _easy_project_files[_easy_filename[:-3]] = str(_easy_contents)
_easy_project_modules = {}

def _easy_load_project_module(name):
    if name in _easy_project_modules:
        return _easy_project_modules[name]
    _easy_module = types.ModuleType(name)
    _easy_module.__file__ = name + '.py'
    _easy_project_modules[name] = _easy_module
    _easy_module.__dict__['__builtins__'] = _easy_builtins
    _easy_module_tree = ast.parse(_easy_project_files[name], filename=name + '.py', mode='exec')
    _easy_validate_tree(_easy_module_tree)
    exec(compile(_easy_module_tree, name + '.py', 'exec'), _easy_module.__dict__, _easy_module.__dict__)
    return _easy_module

def _easy_import(name, globals=None, locals=None, fromlist=(), level=0):
    root_name = name.split('.')[0]
    if root_name in _easy_blocked:
        raise ImportError('This module is not available in the learning runner.')
    if level == 0 and name in _easy_project_files:
        return _easy_load_project_module(name)
    return _easy_original_import(name, globals, locals, fromlist, level)

def _easy_no_files(*args, **kwargs):
    raise PermissionError('File access is disabled in the learning runner.')

_easy_builtins = dict(vars(builtins))
_easy_builtins.pop('open', None)
_easy_builtins['__import__'] = _easy_import
_easy_input_values = list(__easy_inputs)
_easy_output = io.StringIO()
def _easy_input(prompt=''):
    if prompt:
        _easy_output.write(str(prompt))
    if not _easy_input_values:
        raise EOFError('No more sample input was provided.')
    return str(_easy_input_values.pop(0))
_easy_builtins['input'] = _easy_input

def _easy_validate_tree(tree):
    for _easy_node in ast.walk(tree):
        if isinstance(_easy_node, (ast.Import, ast.ImportFrom)):
            _easy_names = [alias.name.split('.')[0] for alias in _easy_node.names] if isinstance(_easy_node, ast.Import) else [_easy_node.module.split('.')[0] if _easy_node.module else '']
            if any(name in _easy_blocked for name in _easy_names):
                raise ImportError('This module is not available in the learning runner.')
        if isinstance(_easy_node, ast.Call) and isinstance(_easy_node.func, ast.Name) and _easy_node.func.id in ('open', 'eval', 'exec', 'compile'):
            if _easy_node.func.id != 'exec':
                raise PermissionError('This operation is disabled in the learning runner.')

try:
    _easy_tree = ast.parse(__easy_source, mode='exec')
    _easy_validate_tree(_easy_tree)
    _easy_namespace = {'__builtins__': _easy_builtins}
    with contextlib.redirect_stdout(_easy_output):
        exec(compile(_easy_tree, '<learner-code>', 'exec'), _easy_namespace, _easy_namespace)
    _easy_result = {'stdout': _easy_output.getvalue()[:65536], 'stderr': '', 'error': None}
except BaseException as _easy_error:
    _easy_error_name = type(_easy_error).__name__
    _easy_error_detail = str(_easy_error).strip()
    if not _easy_error_detail:
        _easy_error_detail = 'Assertion failed.' if _easy_error_name == 'AssertionError' else 'No additional error details.'
    _easy_trace = _easy_error.__traceback__
    _easy_line = getattr(_easy_error, 'lineno', None)
    while _easy_trace is not None:
        if _easy_trace.tb_frame.f_code.co_filename == '<learner-code>':
            _easy_line = _easy_trace.tb_lineno
        _easy_trace = _easy_trace.tb_next
    _easy_location = f' on line {_easy_line}' if _easy_line is not None else ''
    _easy_result = {'stdout': _easy_output.getvalue()[:65536], 'stderr': '', 'error': f'{_easy_error_name}{_easy_location}: {_easy_error_detail}', 'errorType': _easy_error_name, 'line': _easy_line}
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
    pyodide.globals.delete('__easy_files');
  }
}

self.onmessage = (event) => {
  run(event.data);
};

initialize().catch((error) => self.postMessage({type: 'workerError', error: String(error)}));
