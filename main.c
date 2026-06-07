/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
CAN_HandleTypeDef hcan;

UART_HandleTypeDef huart2;

/* USER CODE BEGIN PV */
CAN_TxHeaderTypeDef TxHeader;
CAN_RxHeaderTypeDef RxHeader;
uint8_t TxData[8];
uint8_t RxData[8];
uint32_t TxMailbox;

uint32_t obd_seq_num = 0;

// High-frequency PIDs (0x0C RPM, 0x0D Speed) sprinkled in for smoother UI
const uint8_t pollPids[] = {
    0x0C, 0x0D, 0x11, 0x04,
    0x0C, 0x05, 0x49, 0x2F,
    0x0C, 0x0D, 0x0F, 0x42,
    0x0C, 0x45, 0x10, 0x0E,
    0x0C, 0x0D, 0x0B, 0x46,
    0x0C, 0x33, 0x5C, 0x5E,
    0x0C, 0x0D, 0x62, 0x06,
    0x0C, 0x07, 0x43, 0x44,
    0x0C, 0x0D, 0x3C, 0x0A,
    0x0C, 0x1F, 0x22, 0x2C,
    0x0C, 0x0D, 0x2D, 0x11
};
uint8_t pid_idx = 0;
uint32_t last_poll_time = 0;
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART2_UART_Init(void);
static void MX_CAN_Init(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
int _write(int file, char *ptr, int len) {
  HAL_UART_Transmit(&huart2, (uint8_t *)ptr, (uint16_t)len, 10);
  return len;
}

void HAL_CAN_RxFifo0MsgPendingCallback(CAN_HandleTypeDef *hcan) {
  if (HAL_CAN_GetRxMessage(hcan, CAN_RX_FIFO0, &RxHeader, RxData) == HAL_OK) {
    // OBD2 Standard Responses are 0x7E8 ~ 0x7EF
    if (RxHeader.IDE == CAN_ID_STD && RxHeader.StdId >= 0x7E8 && RxHeader.StdId <= 0x7EF) {
        uint8_t frame_type = RxData[0] & 0xF0;
        
        // Only process ISO-TP Single Frames (0x00)
        if (frame_type == 0x00) {
            uint8_t len = RxData[0] & 0x0F;
            if (len > 7) len = 7;
            
            // Mode 1 Response is 0x41
            if (RxData[1] == 0x41) {
                char out_str[50];
                obd_seq_num++;
                
                int offset = sprintf(out_str, "%lu,", obd_seq_num);
                for (int i = 1; i <= len; i++) {
                    if (i > 1) {
                        offset += sprintf(out_str + offset, " %02X", RxData[i]);
                    } else {
                        offset += sprintf(out_str + offset, "%02X", RxData[i]); // 41
                    }
                }
                out_str[offset++] = '\n';
                out_str[offset] = '\0';
                
                HAL_UART_Transmit(&huart2, (uint8_t *)out_str, offset, 10);
            }
        }
    }
  }
}
/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_USART2_UART_Init();
  MX_CAN_Init();
  /* USER CODE BEGIN 2 */
  CAN_FilterTypeDef sFilterConfig;
  sFilterConfig.FilterBank = 0;
  sFilterConfig.FilterMode = CAN_FILTERMODE_IDMASK;
  sFilterConfig.FilterScale = CAN_FILTERSCALE_32BIT;
  sFilterConfig.FilterIdHigh = 0x0000;
  sFilterConfig.FilterIdLow = 0x0000;
  sFilterConfig.FilterMaskIdHigh = 0x0000;
  sFilterConfig.FilterMaskIdLow = 0x0000;
  sFilterConfig.FilterFIFOAssignment = CAN_RX_FIFO0;
  sFilterConfig.FilterActivation = ENABLE;
  sFilterConfig.SlaveStartFilterBank = 0;

  if (HAL_CAN_ConfigFilter(&hcan, &sFilterConfig) != HAL_OK) {
    Error_Handler();
  }

  if (HAL_CAN_Start(&hcan) != HAL_OK) {
    Error_Handler();
  }

  if (HAL_CAN_ActivateNotification(&hcan, CAN_IT_RX_FIFO0_MSG_PENDING) != HAL_OK) {
    Error_Handler();
  }

  // HAL_UART_Receive_IT(&huart2, &uart_rx_byte, 1);
  /* USER CODE END 2 */
  HAL_UART_Transmit(&huart2, (uint8_t *)"Board Ready - OBD2 Polling Mode\n", 32, 100);
  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    if (HAL_GetTick() - last_poll_time >= 20) {
        last_poll_time = HAL_GetTick();
        
        CAN_TxHeaderTypeDef tx_hdr;
        tx_hdr.StdId = 0x7DF; // Broadcast OBD request
        tx_hdr.ExtId = 0;
        tx_hdr.IDE = CAN_ID_STD;
        tx_hdr.RTR = CAN_RTR_DATA;
        tx_hdr.DLC = 8;
        tx_hdr.TransmitGlobalTime = DISABLE;
        
        uint8_t tx_data[8] = {0x02, 0x01, pollPids[pid_idx], 0x00, 0x00, 0x00, 0x00, 0x00};
        
        if (HAL_CAN_GetTxMailboxesFreeLevel(&hcan) > 0) {
            HAL_CAN_AddTxMessage(&hcan, &tx_hdr, tx_data, &TxMailbox);
            
            pid_idx++;
            if (pid_idx >= sizeof(pollPids)) pid_idx = 0;
        }
    }
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI48;
  RCC_OscInitStruct.HSI48State = RCC_HSI48_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_NONE;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_HSI48;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_1) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief CAN Initialization Function
  * @param None
  * @retval None
  */
static void MX_CAN_Init(void)
{
  /* USER CODE BEGIN CAN_Init 0 */

  /* USER CODE END CAN_Init 0 */

  /* USER CODE BEGIN CAN_Init 1 */

  /* USER CODE END CAN_Init 1 */
  hcan.Instance = CAN;
  hcan.Init.Prescaler = 6;
  hcan.Init.Mode = CAN_MODE_NORMAL;
  hcan.Init.SyncJumpWidth = CAN_SJW_1TQ;
  hcan.Init.TimeSeg1 = CAN_BS1_13TQ;
  hcan.Init.TimeSeg2 = CAN_BS2_2TQ;
  hcan.Init.TimeTriggeredMode = DISABLE;
  hcan.Init.AutoBusOff = DISABLE;
  hcan.Init.AutoWakeUp = DISABLE;
  hcan.Init.AutoRetransmission = DISABLE;
  hcan.Init.ReceiveFifoLocked = DISABLE;
  hcan.Init.TransmitFifoPriority = DISABLE;
  if (HAL_CAN_Init(&hcan) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN CAN_Init 2 */

  /* USER CODE END CAN_Init 2 */
}

/**
  * @brief USART2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART2_UART_Init(void)
{
  /* USER CODE BEGIN USART2_Init 0 */

  /* USER CODE END USART2_Init 0 */

  /* USER CODE BEGIN USART2_Init 1 */

  /* USER CODE END USART2_Init 1 */
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 115200;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  huart2.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
  huart2.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;
  if (HAL_UART_Init(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART2_Init 2 */

  /* USER CODE END USART2_Init 2 */
}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  /* USER CODE BEGIN MX_GPIO_Init_1 */

  /* USER CODE END MX_GPIO_Init_1 */

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOF_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();

  /* USER CODE BEGIN MX_GPIO_Init_2 */

  /* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */
/* USER CODE BEGIN 4 */

/* USER CODE END 4 */
/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  * where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
