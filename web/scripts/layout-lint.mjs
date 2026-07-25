import fs from 'node:fs'
import path from 'node:path'

const root = process.cwd()
const sourceRoot = path.join(root, 'src')
const viewsRoot = path.join(sourceRoot, 'views')

function listFiles(dir, extension) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dir, entry.name)
    return entry.isDirectory()
      ? listFiles(full, extension)
      : entry.name.endsWith(extension)
        ? [full]
        : []
  })
}

const pages = listFiles(viewsRoot, '.vue')
const sourceFiles = [
  ...listFiles(sourceRoot, '.vue'),
  ...listFiles(sourceRoot, '.css'),
  ...listFiles(sourceRoot, '.js'),
]
const routeSource = fs.readFileSync(path.join(sourceRoot, 'router', 'index.js'), 'utf8')
const routeRecords = [...routeSource.matchAll(/\{\s*path:\s*'([^']+)'/g)].map((match) => match[1])
const routeViews = [...routeSource.matchAll(/component:\s*\(\)\s*=>\s*import\('\.\.\/views\/([^']+\.vue)'\)/g)]
  .map((match) => match[1])
const routeRedirects = [...routeSource.matchAll(/\{\s*path:\s*'([^']+)',\s*redirect:\s*'([^']+)'/g)]
  .map((match) => ({ path: match[1], redirect: match[2] }))

const violations = []
const routeCounts = routeRecords.reduce((counts, routePath) => {
  counts.set(routePath, (counts.get(routePath) || 0) + 1)
  return counts
}, new Map())
for (const [routePath, count] of routeCounts) {
  if (count > 1) violations.push(`router: duplicate path ${routePath} (${count})`)
}
for (const route of routeRedirects) {
  if (route.path === route.redirect) {
    violations.push(`router: self redirect ${route.path}`)
  }
}

for (const page of pages) {
  const relative = path.relative(root, page).replaceAll(path.sep, '/')
  const source = fs.readFileSync(page, 'utf8')
  const usesStandaloneTerminalLayout = /data-terminal-layout="terminal"/.test(source)
  if (!usesStandaloneTerminalLayout) {
    for (const [label, pattern] of [
      ['PageContainer', /<PageContainer>/],
      ['PageHeader', /<PageHeader(?:\s|>)/],
      ['SectionCard', /<SectionCard(?:\s|>)/],
    ]) {
      if (!pattern.test(source)) violations.push(`${relative}: missing ${label}`)
    }
  }
  for (const [label, pattern] of [
    ['raw el-table', /<el-table(?=\s|>)/],
    ['raw el-card', /<el-card(?=\s|>)/],
    ['raw el-dialog', /<el-dialog(?=\s|>)/],
    ['legacy page container', /<div class="page-container"/],
    ['legacy page header', /<div class="page-header"/],
    ['local PageContainer layout CSS', /^\s*\.page-container(?:\s|[>{.:#])/m],
    ['local PageHeader layout CSS', /^\s*\.page-header(?:\s|[>{.:#])/m],
    ['local toolbar layout CSS', /^\s*\.(?:tab-)?toolbar(?:\s|[>{.:#])/m],
  ]) {
    if (pattern.test(source)) violations.push(`${relative}: contains ${label}`)
  }
}

for (const file of sourceFiles) {
  const relative = path.relative(root, file).replaceAll(path.sep, '/')
  const source = fs.readFileSync(file, 'utf8')
  for (const [label, pattern] of [
    ['!important', /!important/],
    ['fit-content', /fit-content/],
    ['max-content', /max-content/],
    ['inline-table', /inline-table/],
    ['negative layout margin', /margin-(?:left|right|top|bottom):\s*-\d/],
  ]) {
    if (pattern.test(source)) violations.push(`${relative}: contains ${label}`)
  }
}

for (const routeView of routeViews) {
  const absolute = path.join(viewsRoot, routeView)
  if (!fs.existsSync(absolute)) violations.push(`router: missing view ${routeView}`)
}

const report = {
  routeRecords: routeRecords.length,
  uniqueRoutePaths: new Set(routeRecords).size,
  routeViewReferences: routeViews.length,
  uniqueRouteViews: new Set(routeViews).size,
  businessPages: pages.length,
  migratedPages: pages.length - new Set(violations.filter((item) => item.includes('src/views/')).map((item) => item.split(':')[0])).size,
  rawBusinessTables: pages.reduce((count, page) => count + (fs.readFileSync(page, 'utf8').match(/<el-table(?=\s|>)/g) || []).length, 0),
  violations,
}

console.log(JSON.stringify(report, null, 2))
if (violations.length) process.exitCode = 1
