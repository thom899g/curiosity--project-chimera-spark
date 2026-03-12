"""
Decentralized Data Pipeline - The Senses
Primary: Chainlink Data Feeds (Sepolia)
Fallback: DEX pool reserves (Uniswap V2 fork)
"""
import asyncio
import structlog
from typing import Dict, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime
from tenacity import retry, stop_after_attempt, wait_exponential

import pandas as pd
from web3 import Web3
from web3.exceptions import ContractLogicError
from pydantic import BaseModel, validator

from src.core.firebase_client import FirebaseClient

logger = structlog.get_logger(__name__)

@dataclass
class PriceData:
    """Validated price data structure"""
    timestamp: datetime
    price_eth_usd: float
    source: str  # 'chainlink' or 'dex_fallback'
    confidence: float  # 0.0 to 1.0
    deviation_bps: Optional[int] = None  # Basis points deviation from other source


class PriceValidator(BaseModel):
    """Pydantic model for price validation"""
    chainlink_price: float
    dex_price: Optional[float] = None
    max_deviation_bps: int = 200  # 2% default
    
    @validator('chainlink_price')
    def validate_chainlink_price(cls, v):
        if v <= 0:
            raise ValueError('Chainlink price must be positive')
        if v > 10000:  # Sanity check for ETH price
            raise ValueError(f'Unrealistic ETH price: ${v}')
        return v
    
    def validate_price_match(self) -> Tuple[bool, Optional[int]]:
        """Validate that prices are within acceptable deviation"""
        if self.dex_price is None:
            return True, None  # Only Chainlink available
            
        deviation = abs(self.chainlink_price - self.dex_price) / self.chainlink_price
        deviation_bps = int(deviation * 10000)
        
        if deviation_bps > self.max_deviation_bps:
            logger.warning(
                'Price deviation exceeds threshold',
                chainlink=self.chainlink_price,
                dex=self.dex_price,
                deviation_bps=deviation_bps,
                threshold=self.max_dev