let currentJobData = null

window.addEventListener("message", (event) => {
  const data = event.data

  switch (data.action) {
    case "openJobMenu":
      openJobMenu(data)
      break
    case "closeJobMenu":
      closeUI()
      break
    case "updateXP":
      updateXPDisplay(data)
      break
  }
})

function openJobMenu(data) {
  currentJobData = data

  document.getElementById("job-name").textContent = data.jobName
  document.getElementById("job-level").textContent = `Level ${data.xpData.level}`

  updateXPDisplay(data.xpData)
  updateButtonStates(data.isClockedIn)

  const container = document.getElementById("jobcore-container")
  container.classList.remove("hidden")

  container.focus()
}

function updateXPDisplay(xpData) {
  const currentXP = document.getElementById("current-xp")
  const neededXP = document.getElementById("needed-xp")
  const xpProgress = document.getElementById("xp-progress")
  const xpStatus = document.getElementById("xp-status")

  if (xpData.maxed) {
    currentXP.textContent = xpData.xp
    neededXP.textContent = xpData.xp
    xpProgress.style.width = "100%"
    xpStatus.textContent = "Maximum level reached"
  } else {
    currentXP.textContent = xpData.progress
    neededXP.textContent = xpData.needed
    const progressPercent = Math.floor((xpData.progress / xpData.needed) * 100)

    setTimeout(() => {
      xpProgress.style.width = `${progressPercent}%`
    }, 100)

    xpStatus.textContent = `${progressPercent}% complete`
  }
}

function updateButtonStates(isClockedIn) {
  const clockInBtn = document.getElementById("clock-in-btn")
  const clockOutBtn = document.getElementById("clock-out-btn")

  if (isClockedIn) {
    clockInBtn.classList.add("disabled")
    clockOutBtn.classList.remove("disabled")
  } else {
    clockInBtn.classList.remove("disabled")
    clockOutBtn.classList.add("disabled")
  }
}

function clockIn() {
  if (!currentJobData) return

  const button = document.getElementById("clock-in-btn")
  if (button.classList.contains("disabled")) return

  button.style.opacity = "0.7"
  button.style.pointerEvents = "none"

  fetch(`https://sentrix_jobcore/clockAction`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      action: "clockIn",
      jobName: currentJobData.jobName,
      jobData: currentJobData.jobData,
    }),
  }).finally(() => {
    button.style.opacity = ""
    button.style.pointerEvents = ""
  })

  closeUI()
}

function clockOut() {
  if (!currentJobData) return

  const button = document.getElementById("clock-out-btn")
  if (button.classList.contains("disabled")) return

  button.style.opacity = "0.7"
  button.style.pointerEvents = "none"

  fetch(`https://sentrix_jobcore/clockAction`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      action: "clockOut",
      jobName: currentJobData.jobName,
      jobData: currentJobData.jobData,
    }),
  }).finally(() => {
    button.style.opacity = ""
    button.style.pointerEvents = ""
  })

  closeUI()
}

function closeUI() {
  const container = document.getElementById("jobcore-container")

  container.style.opacity = "0"
  container.style.transform = "scale(0.95)"

  setTimeout(() => {
    container.classList.add("hidden")
    container.style.opacity = ""
    container.style.transform = ""
    currentJobData = null
  }, 200)

  fetch(`https://sentrix_jobcore/closeUI`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({}),
  })
}

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") {
    closeUI()
  }
})

document.addEventListener("contextmenu", (event) => {
  event.preventDefault()
})

document.addEventListener("DOMContentLoaded", () => {
  document.body.style.transition = "all 0.3s ease"
})
