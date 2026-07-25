import { createApp } from 'vue'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'
import App from './App.vue'
import router from './router'
import AppContent from './components/AppContent.vue'
import PageContainer from './components/PageContainer.vue'
import PageHeader from './components/PageHeader.vue'
import SectionCard from './components/SectionCard.vue'
import CardHeader from './components/CardHeader.vue'
import CardToolbar from './components/CardToolbar.vue'
import CardContent from './components/CardContent.vue'
import StandardTable from './components/StandardTable.vue'
import StandardModal from './components/StandardModal.vue'
import StandardDrawer from './components/StandardDrawer.vue'
import FormSection from './components/FormSection.vue'
import EmptyState from './components/EmptyState.vue'
import LoadingState from './components/LoadingState.vue'
import BrandLogo from './components/brand/BrandLogo.vue'
import BrandSymbol from './components/brand/BrandSymbol.vue'
import ProductName from './components/brand/ProductName.vue'
import BRAND from './config/brand.js'
import './styles/layout-tokens.css'
import './styles/global.css'

const app = createApp(App)

for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

const layoutComponents = {
  AppContent,
  PageContainer,
  PageHeader,
  SectionCard,
  CardHeader,
  CardToolbar,
  CardContent,
  StandardTable,
  StandardModal,
  StandardDrawer,
  FormSection,
  EmptyState,
  LoadingState,
  BrandLogo,
  BrandSymbol,
  ProductName,
}

for (const [name, component] of Object.entries(layoutComponents)) {
  app.component(name, component)
}

app.use(ElementPlus)
app.use(router)
document.title = BRAND.productName
app.mount('#app')
