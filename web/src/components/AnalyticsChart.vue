<template>
  <div
    ref="chartElement"
    class="analytics-chart"
    data-layout="analytics-chart"
    :style="{ height: `${height}px` }"
  ></div>
</template>

<script setup>
import { nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import * as echarts from 'echarts'

const props = defineProps({
  option: { type: Object, required: true },
  height: { type: Number, default: 300 },
})

const chartElement = ref(null)
let chart = null
let observer = null

function render() {
  if (!chart || !props.option) return
  chart.setOption(props.option, { notMerge: true })
}

onMounted(async () => {
  await nextTick()
  chart = echarts.init(chartElement.value)
  render()
  observer = new ResizeObserver(() => chart?.resize())
  observer.observe(chartElement.value)
})

watch(() => props.option, render, { deep: true })

onUnmounted(() => {
  observer?.disconnect()
  chart?.dispose()
  observer = null
  chart = null
})
</script>

<style scoped>
.analytics-chart {
  width: 100%;
  min-width: 0;
}
</style>

