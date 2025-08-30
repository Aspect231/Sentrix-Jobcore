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

  document.getElementById("jobcore-container").classList.remove("hidden")
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
    xpStatus.textContent = "Max Level Reached"
  } else {
    currentXP.textContent = xpData.progress
    neededXP.textContent = xpData.needed
    const progressPercent = Math.floor((xpData.progress / xpData.needed) * 100)
    xpProgress.style.width = `${progressPercent}%`
    xpStatus.textContent = `Level ${xpData.level} Progress`
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

  fetch(`https://sentrix_jobcore/clockAction`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      action: "clockIn",
      jobName: currentJobData.jobName,
      jobData: currentJobData.jobData,
    }),
  })

  closeUI()
}

function clockOut() {
  if (!currentJobData) return

  fetch(`https://sentrix_jobcore/clockAction`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      action: "clockOut",
      jobName: currentJobData.jobName,
      jobData: currentJobData.jobData,
    }),
  })

  closeUI()
}

function closeUI() {
  document.getElementById("jobcore-container").classList.add("hidden")
  currentJobData = null

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
