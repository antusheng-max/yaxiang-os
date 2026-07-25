import fs from 'node:fs'
import path from 'node:path'
import { compileScript, compileTemplate, parse } from '@vue/compiler-sfc'

const root = process.cwd()
const sourceRoot = path.join(root, 'src')

function listVueFiles(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dir, entry.name)
    return entry.isDirectory() ? listVueFiles(full) : entry.name.endsWith('.vue') ? [full] : []
  })
}

const failures = []
const files = listVueFiles(sourceRoot)

for (const file of files) {
  const relative = path.relative(root, file).replaceAll(path.sep, '/')
  const source = fs.readFileSync(file, 'utf8')
  const id = Buffer.from(relative).toString('hex').slice(0, 12)
  const parsed = parse(source, { filename: relative })
  if (parsed.errors.length) {
    failures.push({ file: relative, stage: 'parse', errors: parsed.errors.map(String) })
    continue
  }
  const { descriptor } = parsed
  try {
    let bindings
    if (descriptor.scriptSetup) {
      const compiledScript = compileScript(descriptor, { id })
      bindings = compiledScript.bindings
    }
    if (descriptor.template) {
      const compiledTemplate = compileTemplate({
        source: descriptor.template.content,
        filename: relative,
        id,
        scoped: descriptor.styles.some((style) => style.scoped),
        compilerOptions: { bindingMetadata: bindings },
      })
      if (compiledTemplate.errors.length) {
        failures.push({ file: relative, stage: 'template', errors: compiledTemplate.errors.map(String) })
      }
    }
  } catch (error) {
    failures.push({ file: relative, stage: 'compile', errors: [String(error)] })
  }
}

console.log(JSON.stringify({ files: files.length, failures }, null, 2))
if (failures.length) process.exitCode = 1
